use crate::{types::*, *};
use clap::Parser;
use futures::StreamExt;
use inotify::{Inotify, WatchMask};
use serde::{Deserialize, Serialize};
use std::{env, fmt, io::Write, path::*};

use self::backend::Backend;

#[derive(
    Debug, clap::Subcommand, Clone, Copy, Default, strum_macros::Display, Serialize, Deserialize,
)]
#[strum(serialize_all = "lowercase")]
pub enum Subcommand {
    /// Monitor the contents of the icon file
    MonitorIcon,
    /// Create a monitor that updates the status based on plug/unplug events
    StatusMonitor,

    /// Get the status icon
    GetIcon,
    /// Get the status text
    GetStatus,

    /// Manually toggle touchpad state
    Toggle,
    /// Enable the touchpad
    Enable,
    /// Disable the touchpad
    Disable,
    /// Determine the touchpad state from available devices and set or unset as needed
    #[default]
    Normalize,
}
impl Subcommand {
    /// returns true if this is a locking subcommand, requiring a file lock and whatnot.
    pub fn is_locking(&self) -> bool {
        match self {
            Self::StatusMonitor => true,
            _ => false,
        }
    }
}

// why is rustdoc so bad, all I want are newlines fml
///A pointer monitoring program.
///
/// Device names are specified in the same format as the backend requires.
///
/// I set the defaults because I don't want to type them out all the time.
///
/// In hyprland, it is the name that shows up in `hyprctl devices`.
/// In xorg, it is the name that shows up in `xinput`.
///
/// TODO: Implement xorg-xinput backend
#[derive(Debug, Parser, Clone, Serialize, Deserialize)]
#[command(author, version, about, long_about)]
pub struct Args {
    /// The action to take
    #[command(subcommand)]
    pub command: Subcommand,
    /// The specific backend to use
    #[arg(short, long, default_value_t = Backend::default())]
    pub backend: Backend,
    /// The type of match to do when comparing device names
    #[arg(short, long, default_value_t = MatchType::default())]
    pub match_type: MatchType,
    /// The path to the lockfile. This doubles as the file that the icon is printed to.
    #[arg(short, long, default_value_t = Lockfile::default())]
    pub lock_file: Lockfile,
    /// The X display to use when using the xorg backend
    #[arg(long, required = false)]
    pub display: Option<String>,
    /// The name of your touchpad, according to your backend.
    #[arg(long, default_value_t = DEFAULT_DEVICES.0.clone())]
    pub touchpad_name: String,
    /// The names of all your mice, like "mouse1" "mouse2"
    #[arg(last = true, required = false)]
    mouse_names: Vec<String>,
}
impl Args {
    pub async fn exec(&self) -> PResult<()> {
        self.backend.exec(self.command).await?;
        Ok(())
    }
    pub fn get_device_names<'a>(&'a self) -> (&'a String, &'a Vec<String>) {
        (&self.touchpad_name, self.get_mouse_names())
    }
    /// hack to workaround clap argument stuff
    pub fn get_mouse_names<'a>(&'a self) -> &'a Vec<String> {
        if self.mouse_names.len() == 0 {
            &DEFAULT_DEVICES.1
        } else {
            &self.mouse_names
        }
    }
    #[inline]
    pub fn is_locked(&self) -> bool {
        self.lock_file.is_locked
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Lockfile {
    pub path: PathBuf,
    display: String,
    pub is_locked: bool,
}
impl Lockfile {
    pub fn new<P>(filepath: P) -> Option<Self>
    where
        P: AsRef<Path>,
    {
        let path = filepath.as_ref();
        if let Some(parent) = path.parent() {
            if parent.exists() {
                return Some(Self {
                    path: path.into(),
                    display: path.to_string_lossy().to_string(),
                    is_locked: path.exists(),
                });
            }
        }
        None
    }
    pub fn tmpdir() -> PathBuf {
        if let Ok(d) = env::var("XDG_RUNTIME_DIR") {
            let rtd = Path::new(&d);
            if rtd.is_dir() {
                return rtd.to_path_buf();
            }
        }
        // no xdg runtime dir, default to /tmp
        env::temp_dir()
    }
    /// Monitor changes to self. This is async-blocking, designed to run infinitely.
    pub async fn inotify(&self) -> PResult<()> {
        // let icon_file = &CONFIG.lock_file;
        // let mouse_names = CONFIG.get_device_names()?.1;
        if !self.is_locked {
            return Err(PError::NotLocked);
        }

        let listener = Inotify::init()?;

        listener.watches().add(&self.path, WatchMask::MODIFY)?;

        let mut buffer = [0; 1024];
        let mut stream = listener.into_event_stream(&mut buffer)?;

        let mut stdout = std::io::stdout().lock();

        // initial state
        self.cat(&mut stdout)?;

        // I want to give it 5 chances to read the file before I give up.
        // This is because I am using a systemd service to start the daemon, and I am using waybar to start this.
        let mut timeout_count: u8 = 0;
        let timeout = std::time::Duration::from_secs(1);

        while stream.next().await.is_some() {
            if let Err(e) = self.cat(&mut stdout) {
                timeout_count += 1;
                if timeout_count >= 5 {
                    return Err(e);
                } else {
                    tokio::time::sleep(timeout).await;
                }
            }
        }

        Ok(())
    }
    fn cat(&self, stdout: &mut std::io::StdoutLock<'_>) -> PResult<()> {
        let my_string = std::fs::read_to_string(&self.path)? + "\n";
        stdout.write(my_string.as_bytes())?;
        Ok(())
    }
}
impl Default for Lockfile {
    fn default() -> Self {
        let path = Self::tmpdir().join("pointer_status.lock");
        if let Some(p) = Self::new(&path) {
            return p;
        } else {
            panic!(
                "Could not resolve default lockfile path: {}",
                &path.to_string_lossy()
            )
        }
    }
}
impl std::str::FromStr for Lockfile {
    type Err = &'static str;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if let Some(p) = Self::new(s) {
            return Ok(p);
        } else {
            return Err("Could not get the lockfile!");
        }
    }
}
impl fmt::Display for Lockfile {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.display.fmt(f)
    }
}

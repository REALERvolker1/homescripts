use crate::{types::*, CONFIG};
use futures::StreamExt;
use inotify::{Inotify, WatchMask};
use serde::{Deserialize, Serialize};
use std::{
    env, fmt, fs,
    io::{self, Write},
    path::*,
    process,
    str::FromStr,
    time,
};
use tokio::signal::unix::{self, SignalKind};
macro_rules! sig {
    ($signal:tt) => {
        unix::signal(SignalKind::$signal())?
    };
}

// /// Starts a tokio task that monitors for termination signals and cleans up the lockfile upon receiving them
// pub async fn register_cleanup() -> Option<tokio::task::JoinHandle<()>> {
//     if CONFIG.is_locked() {
//         Some(tokio::spawn(async move {
//             if let Err(e) = cleanup_handles().await {
//                 println!("Error received in cleanup: {e}")
//             }
//         }))
//     } else {
//         None
//     }
// }

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
    pub async fn inotify(&self) -> PNul {
        // let icon_file = &CONFIG.lock_file;
        // let mouse_names = CONFIG.get_device_names()?.1;
        if !self.is_locked {
            return Err(PError::NotLocked);
        }

        let listener = Inotify::init()?;

        listener.watches().add(&self.path, WatchMask::MODIFY)?;

        let mut buffer = [0; 1024];
        let mut stream = listener.into_event_stream(&mut buffer)?;

        let mut stdout = io::stdout().lock();

        // initial state
        self.cat(&mut stdout)?;

        // I want to give it 5 chances to read the file before I give up.
        // This is because I am using a systemd service to start the daemon, and I am using waybar to start this.
        let mut timeout_count: u8 = 0;
        let timeout = time::Duration::from_secs(1);

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
    fn cat(&self, stdout: &mut io::StdoutLock<'_>) -> PNul {
        let my_string = fs::read_to_string(&self.path)? + "\n";
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
impl FromStr for Lockfile {
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
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.display.fmt(f)
    }
}

pub async fn cleanup_handles() -> PNul {
    let mut sigint = sig!(interrupt);
    let mut sigalm = sig!(alarm);
    let mut sighup = sig!(hangup);
    let mut sigpipe = sig!(pipe);
    let mut sigquit = sig!(quit);
    let mut sigterm = sig!(terminate);

    let mut received_signal = false;
    let mut signal_type = SignalKind::user_defined1();
    let mut signal_name = "";
    tokio::select! {
        Some(_) = sigint.recv() => {
            received_signal = true;
            signal_type = SignalKind::interrupt();
            signal_name = "INT";
        }
        Some(_) = sigalm.recv() => {
            received_signal = true;
            signal_type = SignalKind::alarm();
            signal_name = "ALM";
        }
        Some(_) = sighup.recv() => {
            received_signal = true;
            signal_type = SignalKind::hangup();
            signal_name = "HUP";
        }
        Some(_) = sigpipe.recv() => {
            received_signal = true;
            signal_type = SignalKind::pipe();
            signal_name = "PIPE";
        }
        Some(_) = sigquit.recv() => {
            received_signal = true;
            signal_type = SignalKind::quit();
            signal_name = "QUIT";
        }
        Some(_) = sigterm.recv() => {
            received_signal = true;
            signal_type = SignalKind::terminate();
            signal_name = "TERM";
        }
    }

    if received_signal {
        eprintln!("Received signal: SIG{signal_name} ({:?})", signal_type);
        if let Err(e) = cleanup().await {
            eprintln!("Cleanup error: {e}");
        } else {
            eprintln!("Cleaned up");
        }
    } else {
        eprintln!("No signals received, but the future returned!");
        cleanup().await?;
    }

    process::exit(signal_type.as_raw_value());
    Ok(())
}

pub async fn cleanup() -> PNul {
    tokio::fs::remove_file(&CONFIG.lockfile.path).await?;
    Ok(())
}

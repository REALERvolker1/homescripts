//! Config file parser
use crate::{backend::Backend, types::*, *};
use serde::{Deserialize, Serialize};
use std::{env, fmt, path::*, process, str::FromStr};
use tokio::{fs, io};

use self::xorg::Xconnection;

pub const CONFIG_NAME: &str = "pointer";

/// The config file contents
#[derive(Debug, Serialize, Deserialize)]
pub struct ConfigReader {
    pub xorg: DevicesLossy,
    pub hyprland: DevicesLossy,
}
impl ConfigReader {
    pub async fn into_device_config(
        self,
        backend: &Backend,
        config_path: &str,
    ) -> PResult<DeviceConfig> {
        let lossy = match backend {
            Backend::Xorg => self.xorg,
            Backend::Hyprland => self.hyprland,
        };
        Ok(DeviceConfig::try_from_lossy(lossy, *backend, config_path).await?)
    }
    /// Read the configs, getting overrides from the args and environment too
    pub async fn new() -> PResult<Self> {
        Self::from_config_file(default_config_path().await?).await
    }
    /// Read a specific user-defined config file
    pub async fn from_config_file(config_file: PathBuf) -> PResult<Self> {
        let config_string = config_file.to_string_lossy();
        if !config_file.is_file() {
            // TODO: Generate a config file with documentation
            return Err(PError::ConfigParse(
                String::from("Config file does not exist: ") + &config_string,
            ));
        }
        let contents = if let Ok(s) = fs::read_to_string(&config_file).await {
            s
        } else {
            return Err(PError::ConfigParse(
                String::from("Could not read config file: ") + &config_string,
            ));
        };
        // let mut touchpad_name = None;
        // let mut lockfile_path = None;

        let config: ConfigReader = match toml::from_str(&contents) {
            Ok(t) => t,
            Err(e) => return Err(PError::ConfigParse(e.to_string())),
        };

        Ok(config)
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DevicesLossy {
    pub touchpad_name: Option<String>,
    pub mouse_names: Option<Vec<String>>,
    pub match_type: Option<String>,
}

/// The actual main config per-backend
#[derive(Debug, Serialize, Deserialize)]
pub struct DeviceConfig {
    pub touchpad_name: String,
    pub mouse_names: Vec<String>,
    pub match_type: MatchType,
}
impl DeviceConfig {
    /// Try from a config. If any fields are None, implement naive detection methods.
    pub async fn try_from_lossy(
        d: DevicesLossy,
        backend: Backend,
        config_path: &str,
    ) -> PResult<Self> {
        let touchpad_name = if let Some(n) = d.touchpad_name {
            n
        } else {
            eprintln!(
                "No touchpad specified in config file. ({config_path}) Trying naive detection..."
            );
            // autodetect touchpad based on name
            if let Some(t) = backend
                .get_pointers()
                .await?
                .into_iter()
                .map(|m| m.to_ascii_lowercase())
                .filter(|m| m.contains("touch") || m.contains("track"))
                .next()
            {
                t
            } else {
                return Err(PError::ConfigParse(String::from(
                    "Could not find touchpad device!",
                )));
            }
        };

        let (mouse_names, match_type) = if let Some(names) = d.mouse_names {
            let match_type = if let Some(t) = d.match_type {
                MatchType::from_str(&t).unwrap_or_default()
            } else {
                MatchType::default()
            };
            (names, match_type)
        } else {
            eprintln!("No mouse names specified in config file! ({config_path}) Implementing naive detection.");
            (Vec::new(), MatchType::Naive)
        };

        Ok(Self {
            touchpad_name,
            mouse_names,
            match_type,
        })
    }
}

/// This is just here to support argparse.
///
/// It panics if it fails.
pub async fn default_config_path() -> PResult<PathBuf> {
    let mut config_folder = if let Some(c) = xdg_config_home().await {
        c
    } else {
        return Err(PError::ConfigParse("Could not find the config directory. Please set XDG_CONFIG_HOME, or at least the HOME environment variable.".to_owned()));
    };
    config_folder.push(CONFIG_NAME);
    // let config_file = ensure_dir(config_folder).await?.join("config.toml");
    let config_file = if let Ok(c) = ensure_dir(config_folder).await {
        c.join("config.toml")
    } else {
        return Err(PError::ConfigParse(
            "No config file found. Please generate a new one.".to_owned(),
        ));
    };
    Ok(config_file)
}

/// get the user's config home
async fn xdg_config_home() -> Option<PathBuf> {
    if let Ok(c) = env::var("XDG_CONFIG_HOME") {
        let path = PathBuf::from(&c);
        if path.is_dir() {
            return Some(path);
        } else if let Ok(h) = env::var("HOME") {
            let path = Path::new(&h).join(".config");
            if let Ok(d) = ensure_dir(path).await {
                return Some(d);
            }
        }
    }
    None
}
async fn ensure_dir(dir: PathBuf) -> tokio::io::Result<PathBuf> {
    if !dir.is_dir() {
        tokio::fs::create_dir_all(&dir).await?;
    }
    Ok(dir)
}

/// The main config type. All roads lead to this on startup.
#[derive(Debug)]
pub struct Config {
    pub device: DeviceConfig,
    pub xserver_connection: PResult<Xconnection>,
    pub hyprland_touchpad: String,
    pub config_path: PathBuf,
    pub backend: Backend,
    pub action: cli::Action,
    pub lockfile: cleanup::Lockfile,
}
impl Config {
    pub fn new_blocking() -> Self {
        let runtime_handle = tokio::runtime::Handle::current();
        let goard = runtime_handle.enter();
        match futures::executor::block_on(Self::new()) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("{e}");
                process::exit(1);
            }
        }
    }
    pub async fn new() -> PResult<Self> {
        let lockfile = cleanup::Lockfile::default();

        let argparse = cli::Overrides::from_args()?;

        let backend = if let Some(b) = argparse.backend {
            b
        } else {
            Backend::try_new()?
        };

        let config_path = if let Some(a) = argparse.config_path {
            a
        } else {
            default_config_path().await?
        };

        let reader = ConfigReader::from_config_file(config_path.clone()).await?;
        let config_path_string = config_path.to_string_lossy();
        let devconf = reader
            .into_device_config(&backend, &config_path_string)
            .await?;

        let (xserver_connection, hyprland_touchpad) = match backend {
            Backend::Xorg => (
                Ok(Xconnection::new()?),
                format!("Your backend is not hyprland! ({backend})"),
            ),
            Backend::Hyprland => (
                Err(PError::Other(format!(
                    "X connection is not necessary for your backend: {backend}"
                ))),
                backend.keyify(&devconf.touchpad_name),
            ),
        };

        Ok(Self {
            device: devconf,
            xserver_connection,
            hyprland_touchpad,
            config_path,
            backend,
            lockfile,
            action: argparse.action,
        })
    }
    pub fn is_locked(&self) -> bool {
        self.lockfile.is_locked
    }
}

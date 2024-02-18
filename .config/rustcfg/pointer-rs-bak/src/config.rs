use super::*;
use clap::{Parser, Subcommand};

/// By default, it uses these to try to identify the touchpad, unless overridden.
pub const TOUCHPAD_IDENTIFY_CLUES: [&str; 2] = ["touchpad", "trackpad"];
const DEFAULT_MOUSE_IDENTIFIERS: [&str; 2] = ["glorious", "g-pro"];

macro_rules! mouse_idents {
    () => {
        DEFAULT_MOUSE_IDENTIFIERS.map(|m| m.to_owned()).to_vec()
    };
}

pub fn default_touchpad_statusfile() -> PathBuf {
    if let (Ok(run), Ok(id)) = (
        std::env::var("XDG_RUNTIME_DIR"),
        std::env::var("XDG_SESSION_ID"),
    ) {
        let path = PathBuf::from(run);
        if path.is_dir() {
            return path.join(id + ".touchpad_statusfile");
        }
    }
    std::env::temp_dir().join("touchpad_statusfile")
}

#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    clap::ValueEnum,
    PartialEq,
    Eq,
    Subcommand,
    Serialize,
    Deserialize,
    strum_macros::Display,
)]
#[clap(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum Command {
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
    Normalize,
    #[default]
    #[clap(skip)]
    #[serde(skip)]
    Help,
}

#[derive(Debug, Parser, Serialize, Deserialize)]
#[command(author, version, about, long_about = None)]
pub struct Config {
    #[arg(
        short,
        long,
        help = "The backend to use",
        long_help = "Override the backend used. Right now, the only option is 'hyprland'. If none is passed, then it will be autodetected.",
        default_value_t = Backends::default(),
    )]
    pub backend: Backends,
    #[arg(
        short,
        long,
        required = false,
        help = "the name of your touchpad device",
        long_help = "(Part of) the name of your touchpad device, case-insensitively matched. Will be autodetected if not provided."
    )]
    pub touchpad_identifier: Option<String>,
    #[arg(
        short,
        long,
        required = false,
        help = "The names of your mice",
        long_help = "Substrings to case-insensitively search for in mice names. Some defaults will be used if none are provided, but these can cause false positives.",
        default_values_t = mouse_idents!(),
    )]
    pub mouse_identifiers: Vec<String>,
    #[arg(
        long,
        required = false,
        help = "the path to the touchpad statusfile",
        default_value_os_t = default_touchpad_statusfile(),
    )]
    pub touchpad_statusfile: PathBuf,

    #[command(subcommand)]
    pub command: Command,
}
impl Default for Config {
    fn default() -> Self {
        Self {
            backend: Backends::default(),
            touchpad_identifier: None,
            mouse_identifiers: mouse_idents!(),
            touchpad_statusfile: default_touchpad_statusfile(),
            command: Command::default(),
        }
    }
}
impl Config {
    pub fn new() -> Conf {
        Self::parse()
    }
    pub fn is_mouse(&self, mouse_name: &str) -> bool {
        for i in self.mouse_identifiers.iter() {
            if mouse_name.to_ascii_lowercase().contains(i) {
                return true;
            }
        }
        false
    }
    pub async fn read_statusfile(&self) -> tokio::io::Result<String> {
        tokio::fs::read_to_string(&self.touchpad_statusfile).await
    }
    pub async fn update_statusfile(&self, status: Status) -> tokio::io::Result<()> {
        let newlined = status.icon().to_owned() + "\n";
        tokio::fs::write(&self.touchpad_statusfile, &newlined).await
    }
    /// Gets the first touchpad device that matches one of the clues in [`TOUCHPAD_IDENTIFY_CLUES`]
    ///
    /// Only meant to be run once at startup
    pub fn detect_touchpads(&self, devices: &Vec<Mouse>) -> Res<Mouse> {
        if let Some(ident) = self.touchpad_identifier.as_ref() {
            let ident_lowercase = ident.to_ascii_lowercase();
            if let Some(n) = devices
                .iter()
                .filter(|n| n.name.contains(&ident_lowercase))
                .next()
            {
                return Ok(n.clone());
            }
        }

        // it wasn't specified
        for device in devices.iter() {
            for clue in TOUCHPAD_IDENTIFY_CLUES {
                if device.name.contains(clue) {
                    return Ok(device.clone());
                }
            }
        }

        Err(eyre!("No touchpad found"))
    }
}

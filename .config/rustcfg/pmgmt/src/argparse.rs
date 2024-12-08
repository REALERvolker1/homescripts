use {
    crate::{
        logger::{LogColor, LogLevel},
        xmlgen::supergfxd::GfxMode, R,
    },
    ::clap::{Parser, Subcommand},
    ::core::str::FromStr,
    ::serde::{Deserialize, Serialize},
    ::std::path::{Path, PathBuf},
    ::tracing::{error, info, warn},
};

const ROFI_CMD: &str = "rofi";
const AUTODETECTED_RUNNERS: [&str; 3] = ["wofi", "tofi", "dmenu"];

#[derive(Debug, Serialize, Deserialize, Parser)]
#[clap(version, about, long_about = None)]
struct ArgsInner {
    /// The path to the config file
    #[clap(short, long, required = true)]
    pub config: PathBuf,
    /// Whether to use color for stdout logs
    #[clap(long, required = false, default_value_t = LogColor::default())]
    pub color: LogColor,

    /// The logging level
    #[clap(short, long, required = false, default_value_t = LogLevel::default())]
    pub log_level: LogLevel,

    /// The path to the log file, if you want to use one. The default behavior is to use the console.
    #[clap(long)]
    pub logfile: Option<PathBuf>,

    /// Whether to show more details in the logs (for debugging)
    #[clap(long, default_value_t = false)]
    pub log_details: bool,

    #[clap(subcommand)]
    pub action: Action,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Args {
    pub command: RofiCommand,
}
impl Args {
    pub fn new() -> Result<Self, ArgParseError> {
        let args = ArgsInner::parse();

        crate::logger::start_logger(args.color, args.log_details, args.log_level, args.logfile)?;

        let command = match args.rofi_command {
            Some(cmd) => RofiCommand::new(args.rofi_mode, cmd),
            None => RofiCommand::autodetect(),
        }?;

        Ok(Self { command })
    }
}

#[derive(Debug, Clone, Subcommand, Serialize, Deserialize)]
pub enum Action {
    RunGfxMenu {
        /// Set this flag if you want to send the output to rofi-compatible runners. Automatically set if the command is rofi.
        #[clap(long, short, default_value_t = false)]
        rofi_mode: bool,

        /// The rofi command to run
        #[clap(long, required = false)]
        rofi_command: Option<String>,
    },
    Daemon {
        battery_warning: Option<u8>,
        battery_critical_warning: Option<u8>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RofiCommand {
    pub is_rofi: bool,
    pub command: PathBuf,
}
impl Default for RofiCommand {
    fn default() -> Self {
        Self::autodetect().unwrap()
    }
}
impl RofiCommand {
    pub fn autodetect() -> Result<Self, ArgParseError> {
        if let Ok(rofi) = which::which(ROFI_CMD) {
            return Ok(Self {
                is_rofi: true,
                command: rofi,
            });
        }

        for runner in AUTODETECTED_RUNNERS {
            if let Ok(path) = which::which(runner) {
                return Ok(Self {
                    is_rofi: false,
                    command: path,
                });
            }
        }

        Err(ArgParseError::NoRunnerDetected)
    }
    pub fn new(mut is_rofi: bool, command: String) -> Result<Self, ArgParseError> {
        if command == ROFI_CMD {
            is_rofi = true;
        }

        match which::which(command) {
            Ok(binary) => Ok(Self {
                is_rofi,
                command: binary,
            }),
            Err(e) => Err(ArgParseError::MissingCommand(e)),
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum ArgParseError {
    #[error("Missing command: {0}")]
    MissingCommand(which::Error),

    #[error("No compatible runner detected! Please install {ROFI_CMD} or one of {AUTODETECTED_RUNNERS:?}")]
    NoRunnerDetected,

    #[error("Error initializing logger: {0}")]
    Logging(#[from] crate::logger::LogError),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatLevelConfig {
    pub battery_level: u8,
    pub show_warning: bool,
    pub gfx_mode: Option<GfxMode>,
    pub power_profile: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub battery_levels: Vec<BatLevelConfig>,
    pub rofi_command: String,
    pub dmenu_mode: bool,
}
impl Default for Config {
    fn default() -> Self {
        let default_rofi_command = RofiCommand::default();
        Self {
            battery_levels: vec![
                BatLevelConfig {
                    battery_level: 20,
                    show_warning: true,
                    gfx_mode: None,
                    power_profile: None,
                },
                BatLevelConfig {
                    battery_level: 10,
                    show_warning: true,
                    gfx_mode: None,
                    power_profile: None,
                },
            ],
            rofi_command: default_rofi_command
                .command
                .file_name()
                .unwrap()
                .to_string_lossy()
                .to_string(),
            dmenu_mode: default_rofi_command.is_rofi,
        }
    }
}
impl Config {
    const CONFIG_FNAME: &str = "config.toml";
    const CONFIG_DNAME: &str = env!("CARGO_PKG_NAME");

    pub fn default_path() -> PathBuf {
        let mut path = match std::env::var_os("XDG_CONFIG_HOME") {
            Some(p) => PathBuf::from(p),
            None => {
                let mut home = PathBuf::from(
                    std::env::var_os("HOME").expect("Failed to find user home directory!"),
                );
                home.push(".config");
                home
            }
        };
        path.push(Self::CONFIG_DNAME);
        path.push(Self::CONFIG_FNAME);
        path
    }

    pub fn write_to_config(&self, path: &Path) -> R<Self> {
        std::fs::create_dir_all(
            path.parent()
                .expect("Config directory has no parent directory"),
        )?;

        let str = toml_edit::ser::to_string_pretty(self)?;
    }
}

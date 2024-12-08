use {
    crate::xmlgen::{
        power_profiles::PowerProfileState,
        supergfxd::{GfxMode, GfxPower},
    },
    ::core::cell::LazyCell,
    ::serde::{Deserialize, Serialize},
    ::std::{
        env,
        path::{Path, PathBuf},
        rc::Rc,
    },
    ::upowerz::types::BatteryState,
};

fn arg_operation(
    should_generate: bool,
    specified_path: &Path,
) -> Result<Config, ArgParseError<'_>> {
    if should_generate {
        // Config::ge
    }
}

// pub fn argparse_for_config() -> Result<Config, ArgParseError> {
//     let default_config_file_path = LazyCell::new(|| {
//         if let Some(over_ride) = env::var_os(OVERRIDE_ENV_VAR) {
//             return over_ride.into();
//         }

//         let mut path = match env::var_os("XDG_CONFIG_HOME") {
//             Some(c) => PathBuf::from(c),
//             None => {
//                 let mut home_dir =
//                     PathBuf::from(env::var_os("HOME").expect(
//                         "User has no home directory! Please set the $HOME environment variable!!",
//                     ));

//                 home_dir.push(".config");
//                 home_dir
//             }
//         };

//         path.push(env!("CARGO_PKG_NAME"));
//         path.push("config.toml");

//         path
//     });

//     let mut args = env::args_os().skip(1);

//     let Some(first_arg) = args.next() else {
//         return match Config::try_read_default_path() {
//             Ok(c) => Ok(c),
//             Err(e) => match e {
//                 ConfigParseError::FileNotFound(_) => Ok(Config::try_create_example(get_config_file_path())?),
//                 _ => Err(e.into()),
//             },
//         };
//     };

//     let fastr = first_arg.to_string_lossy();

//     match fastr {
//         "--generate" | "-g" => {
//             match args.next() {
//                 Some(chosen_path) => {
//                     // Config::try?
//                 }
//             }
//     }
// }

pub fn print_help() {
    println!(
        "Usage: {} [--generate | -g] [/path/to/config.toml | ]

--generate | -g: Generate a default config file at the specified path.
If no path is specified, it will use the default location for the config file.

Run with no arguments to use the default config file, generating it if it does not exist.

The default config file path can be overridden with the environment variable {OVERRIDE_ENV_VAR}",
        env!("CARGO_BIN_NAME")
    );
}

const OVERRIDE_ENV_VAR: &str = const_format::concatcp!(
    const_format::map_ascii_case!(const_format::Case::Upper, env!("CARGO_PKG_NAME")),
    "_CONFIG"
);

#[derive(Debug, thiserror::Error)]
pub enum ArgParseError<'p> {
    #[error(transparent)]
    Parse(#[from] ConfigParseError<'p>),
    #[error(transparent)]
    Write(#[from] ConfigWriteError<'p>),
}

#[derive(Debug, thiserror::Error)]
pub enum ConfigParseError<'p> {
    #[error("Config file not found: {0}")]
    FileNotFound(&'p Path),
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error(transparent)]
    TomlError(#[from] toml_edit::de::Error),
}

#[derive(Debug, thiserror::Error)]
pub enum ConfigWriteError<'p> {
    #[error("Failed to create path at {0}: {1}")]
    PathCreate(&'p Path, std::io::Error),
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error(transparent)]
    Toml(#[from] toml_edit::ser::Error),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub daemon_config: Vec<ActionRunnerCfg>,
}
impl Default for Config {
    fn default() -> Self {
        Self {
            daemon_config: vec![],
        }
    }
}
impl Config {
    fn try_read(path: &Path) -> Result<Self, ConfigParseError> {
        if !path.is_file() {
            return Err(ConfigParseError::FileNotFound);
        }
        let file_read = std::fs::read(path)?;
        let out = toml_edit::de::from_slice(&file_read)?;

        Ok(out)
    }

    fn try_read_default_path() -> Result<Self, ConfigParseError> {
        match Self::try_read(get_config_file_path()) {
            Ok(c) => Ok(c),
            Err(user_cfg_err) => {
                match Self::try_read(PathBuf::from(concat!(
                    "/etc/",
                    env!("CARGO_PKG_NAME"),
                    ".toml"
                ))) {
                    Ok(c) => Ok(c),
                    Err(etc_cfg_err) => {
                        eprintln!("Failed to read system config: {}", etc_cfg_err);
                        Err(user_cfg_err)
                    }
                }
            }
        }
    }

    pub fn try_create_example(path: PathBuf) -> Result<Self, ConfigWriteError> {
        let path = get_config_file_path();

        std::fs::create_dir_all(path.parent().unwrap_or_default())
            .map_err(|e| ConfigWriteError::PathCreate(path, e))?;

        let me = Self::default();

        let me_toml = toml_edit::ser::to_string_pretty(&me)?;

        println!("Writing default config file to path: {}", path.display());
        eprintln!("{}", me_toml);

        std::fs::write(path, me_toml)?;

        Ok(me)
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ActionRunnerCfg {
    pub when: Vec<ActionCondition>,
    pub do_actions: Vec<Action>,
}

#[derive(Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum ActionCondition {
    Percentage(u8),
    State(BatteryState),
    GfxState(GfxPower),
    GameModeActive(bool),
}

#[derive(Debug, Serialize, Deserialize)]
pub enum Action {
    SetPowerProfile(PowerProfileState),
    SetKeyboardBrightness(i32),
    RunCommand {
        command: String,
        kill_conditions: Vec<ActionCondition>,
    },
    Notify {
        summary: String,
        details: Option<String>,
        icon: Option<String>,
    },
}

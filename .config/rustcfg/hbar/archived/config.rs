use std::io::Write;

use crate::*;

use clap::Parser;

/// A trait that must be present on all config structs. It will be automatically macro'd if you use that.
pub trait Configuration {
    type OverwriteWith;
    fn overwrite_with(&mut self, overwrite_with: Self::OverwriteWith);
}

/// The macro that generates config structs.
/// ```rust
/// config_struct! {
///     ModuleConfig, ModuleConfigOptions,
///
///     default: "foo".to_string(),
///     help: "Short help string",
///     long_help: "This is a longer help string",
///     inner_format: String,
///
///     default: 10,
///     help: "The poll rate",
///     long_help: "The module poll rate, in seconds",
///     poll_rate: u64,
/// }
/// ```
///
#[macro_export]
macro_rules! config_struct {
    ($struct_name:tt, $config_struct_name:tt, $(default: $default_value:expr, help: $help:expr, long_help: $long_help:expr, $field_name:tt: $field_type:ty),+$(,)?) => {
        pub mod config_types {
            use super::*;
            #[derive(Debug, Clone, Serialize, Deserialize, SmartDefault)]
            pub struct $struct_name {
                $(
                    #[default($default_value)]
                    pub $field_name: $field_type,
                )+
            }
            impl crate::config::Configuration for $struct_name {
                type OverwriteWith = $config_struct_name;
                fn overwrite_with(&mut self, overwrite_with: Self::OverwriteWith) {
                    $(
                        if let Some(f) = overwrite_with.$field_name {
                            self.$field_name = f
                        }
                    )+
                }
            }
            #[derive(Debug, Parser, Clone, Serialize, Deserialize, Default)]
            pub struct $config_struct_name {
                $(
                    #[arg(long, help = $help, long_help = $long_help)]
                    pub $field_name: Option<$field_type>,
                )+
            }
            pub type CleanConfig = $struct_name;
            pub type OptionConfig = $config_struct_name;
        }
        // use self::config_types::{CleanConfig, OptionConfig};
    };
}
/// minus `-` to add to partial config only. `+` to add to full config only. `~` to add to both
macro_rules! config_struct_main {
    ($config_full:tt, $config_partial:tt -> $($(~ #[$attr:meta])* $(+ #[$full_attr:meta])* $(- #[$partial_attr:meta])* $key:ident: ($clean_type:ty, $option_type:ty)),+$(,)?) => {
        #[derive(Debug, Default, Serialize, Deserialize)]
        pub struct $config_full {
            $(
                $(#[$attr])*
                $(#[$full_attr])*
                pub $key: $clean_type,
            )+
        }
        impl crate::config::Configuration for $config_full {
            type OverwriteWith = $config_partial;
            fn overwrite_with(&mut self, overwrite_with: Self::OverwriteWith) {
                $(
                    if let Some(f) = overwrite_with.$key {
                        self.$key.overwrite_with(f)
                    }
                )+
            }
        }
        #[derive(Parser, Debug, Default, Serialize, Deserialize)]
        #[command(author, version, about, long_about = None)]
        pub struct $config_partial {
            $(
                $(#[$attr])*
                $(#[$partial_attr])*
                pub $key: Option<$option_type>,
            )+
        }
    };
}

config_struct_main! {
    Config, ConfigPartial ->

    ~ #[serde(skip)]
    - #[command(flatten)]
    config_paths: (config_types::CleanConfig, config_types::OptionConfig),

    - #[arg(skip)]
    modules: (modules::config_types::CleanConfig, modules::config_types::OptionConfig),

    - #[command(flatten)]
    disks: (modules::disks::config_types::CleanConfig, modules::disks::config_types::OptionConfig),
    - #[command(flatten)]
    memory: (modules::memory::config_types::CleanConfig, modules::memory::config_types::OptionConfig),
    - #[command(flatten)]
    cpu: (modules::cpu::config_types::CleanConfig, modules::cpu::config_types::OptionConfig),
    - #[command(flatten)]
    time: (modules::time::config_types::CleanConfig, modules::time::config_types::OptionConfig),
    - #[command(flatten)]
    weather: (modules::weather::config_types::CleanConfig, modules::weather::config_types::OptionConfig),
}
impl Config {
    /// Create a new instance, first parsing args, then loading the config file
    #[tracing::instrument]
    pub fn new() -> ModResult<Self> {
        let config_start = ConfigPartial::try_parse()?;

        let from_override_config_file = if_chain! {
            if let Some(p) = &config_start.config_paths;
            if let Some(f) = &p.config_file;
            then {
                info!("Trying to override config file path with: {}", f.display());
                ConfigPartial::from_file(f)
            }
            else {
                Err("No override file provided".into())
            }
        };

        let from_config_file = match from_override_config_file {
            Ok(c) => c,
            Err(e) => ConfigPartial::from_default_file().unwrap_or_else(|e| {
                error!("Could not parse default config file: {}", e);
                if_chain! {
                    if Self::write_example_config().is_ok();
                    if let Ok(c) = ConfigPartial::from_default_file();
                    then {
                        c
                    }
                    else {
                        error!("Could not parse default config file, even after writing to it!: {}", e);
                        ConfigPartial::default()
                    }
                }
            }),
        };

        let mut default_config = Self::default();
        default_config.overwrite_with(from_config_file);
        default_config.overwrite_with(config_start);

        Ok(default_config)
    }
    /// Write the example config, synchronously
    #[tracing::instrument]
    pub fn write_example_config() -> ModResult<()> {
        let default_config = Self::default();
        let conf_path = &default_config.config_paths.config_file;
        // I really don't want to overwrite anything
        if conf_path.exists() {
            return Ok(());
        }

        let serialized = toml_edit::ser::to_string_pretty(&default_config)?;

        // TODO: Add documentation

        let config_dir = if let Some(p) = conf_path.parent() {
            p
        } else {
            return Err(format!(
                "Config file '{}' has no parent directory",
                conf_path.display()
            )
            .into());
        };

        std::fs::create_dir_all(config_dir)?;

        let mut config = std::fs::File::create(conf_path)?;
        writeln!(config, "{}", serialized)?;

        Ok(())
    }
}
impl fmt::Display for Config {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match toml_edit::ser::to_string_pretty(&self) {
            Ok(s) => write!(f, "{}", s),
            Err(e) => write!(f, "{:?}", e),
        }
    }
}
impl ConfigPartial {
    pub fn from_file(filepath: &Path) -> ModResult<Self> {
        let string_config = std::fs::read_to_string(filepath)?;
        let config_struct = toml_edit::de::from_str::<Self>(&string_config)?;
        Ok(config_struct)
    }
    #[inline]
    pub fn from_default_file() -> ModResult<Self> {
        Self::from_file(&config_path())
    }
}
//

//

//

// #[derive(Parser, Debug, Default, Serialize, Deserialize)]
// #[command(author, version, about, long_about = None)]
// pub struct Config {
//     #[serde(skip)]
//     #[command(flatten)]
//     pub config_paths: ConfigDirs,

//     #[arg(skip)]
//     pub modules: modules::config_types::ModuleConfig,

//     #[command(flatten)]
//     pub memory: modules::memory::config_types::MemoryConfig,
//     #[command(flatten)]
//     pub cpu: modules::cpu::config_types::CpuConfig,
//     #[command(flatten)]
//     pub disks: modules::disks::config_types::DiskConfig,
//     #[command(flatten)]
//     pub time: modules::time::config_types::TimeConfig,
//     #[command(flatten)]
//     pub weather: modules::weather::config_types::CleanConfig,

//     #[serde(skip)]
//     #[command(flatten)]
//     pub verbose: Verbosity<WarnLevel>,
// }
// impl Config {
//     /// Create a new instance, first parsing args, then loading the config file
//     pub fn new() -> ModResult<()> {
//         let config_start = Config::try_parse()?;

//         // let config = ::config::Config::builder().add_source(source)

//         let conf_file = if let Ok(c) = Self::from_file(&config_start.config_paths.config_file) {
//             info!(
//                 "Overriding config file path with: {}",
//                 config_start.config_paths.config_file.display()
//             );
//             Some(c)
//         } else {
//             // TODO: This may be a bit unnecessary since the config parse falls back to default()
//             let default_conf = ConfigDirs::default().config_file;

//             info!(
//                 "Reading config from default path: {}",
//                 default_conf.display()
//             );

//             match Self::from_file(&default_conf) {
//                 Ok(c) => Some(c),
//                 Err(e) => {
//                     error!("Could not parse config file: {}", e);
//                     info!("Trying to create example config...");

//                     match Self::write_example_config() {
//                         Ok(_) => match Self::from_file(&default_conf) {
//                             Ok(c) => Some(c),
//                             Err(e) => {
//                                 error!("Could not parse config file: {}", e);
//                                 None
//                             }
//                         },
//                         Err(e) => {
//                             error!("Could not write example config: {}", e);
//                             None
//                         }
//                     }
//                 }
//             }
//         };

//         Ok(())
//     }
//     pub fn from_file(filepath: &Path) -> ModResult<Self> {
//         let string_config = std::fs::read_to_string(filepath)?;
//         let config_struct = toml_edit::de::from_str::<Self>(&string_config)?;
//         Ok(config_struct)
//     }
//     /// Write the example config, synchronously
//     pub fn write_example_config() -> ModResult<()> {
//         let default_config = Config::default();
//         let serialized = toml_edit::ser::to_string_pretty(&default_config)?;
//         let conf_path = &default_config.config_paths.config_file;

//         // TODO: Add documentation

//         let config_dir = if let Some(p) = conf_path.parent() {
//             p
//         } else {
//             return Err(format!(
//                 "Config file '{}' has no parent directory",
//                 conf_path.display()
//             )
//             .into());
//         };

//         std::fs::create_dir_all(config_dir)?;

//         let mut config = std::fs::File::create(conf_path)?;
//         writeln!(config, "{}", serialized)?;

//         Ok(())
//     }
// }
// impl fmt::Display for Config {
//     fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
//         match toml_edit::ser::to_string_pretty(&self) {
//             Ok(s) => write!(f, "{}", s),
//             Err(e) => write!(f, "{:?}", e),
//         }
//     }
// }

macro_rules! home {
    () => {
        dirs::home_dir()
            .expect("Could not find $HOME")
            .join(concatcp!(".", NAME))
    };
}

config_struct! {
    ConfigDirs, ConfigDirsOptions,

    default: config_path(),
    help: "Override the config file",
    long_help: "Override the config file",
    config_file: PathBuf,

    default: runtime_path(),
    help: "Override the runtime directory",
    long_help: "Override the runtime directory",
    runtime_path: PathBuf,
}
use config_types::ConfigDirs;

// #[derive(Parser, Debug, Clone, SmartDefault, Serialize, Deserialize)]
// pub struct ConfigDirs {
//     #[arg(long, help = "Override the config file", default_value_os_t = config_path())]
//     #[default(config_path())]
//     pub config_file: PathBuf,
//     #[arg(long, help = "Override the runtime directory", default_value_os_t = runtime_path())]
//     #[default(runtime_path())]
//     pub runtime_path: PathBuf,
//     // #[arg(long, help = "Override the log file path", default_value_os_t = Self::log_dir())]
//     // #[default(Self::log_dir())]
//     // pub log_dir: PathBuf,
// }

/// Get the path to the config file. This panics if it can't find any of the other directory
/// options and your `$HOME` variable is not set.
fn config_path() -> PathBuf {
    dirs::config_dir()
        .unwrap_or(home!())
        .join(NAME)
        .join("config.toml")
}
/// Get the path to the runtime directory. This panics if it can't find any of the other directory
/// options and your `$HOME` variable is not set.
fn runtime_path() -> PathBuf {
    dirs::runtime_dir()
        .unwrap_or(dirs::cache_dir().unwrap_or(home!().join("run")))
        .join(NAME)
}

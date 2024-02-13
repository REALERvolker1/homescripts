use std::io::Write;

use crate::*;

use clap::Parser;
use heck::ToKebabCase;

pub type HelpVariants = Option<&'static [(&'static str, &'static str)]>;
/// A trait that must be present on all config structs. It will be automatically macro'd if you use that.
pub trait Configuration {
    const SHORT_HELP_VARIANTS: HelpVariants;
    const LONG_HELP_VARIANTS: HelpVariants;
    type OverwriteWith;
    /// Overwrite this struct with the value of its shadow counterpart. This is used internally in arg and config parsing.
    fn overwrite_with(&mut self, overwrite_with: Self::OverwriteWith);
    /// Get associated help text for this config. Each lookup is `O(n)`
    fn get_short_help(query: &str) -> Option<&'static str> {
        let query_cased = query.to_kebab_case();
        let help = Self::SHORT_HELP_VARIANTS?
            .iter()
            .find(|v| &query_cased == v.0)?
            .1;
        Some(help)
    }
    /// Get associated long help text for this config. Reemember that each lookup is `O(n)`
    fn get_long_help(query: &str) -> Option<&'static str> {
        let query_cased = query.to_kebab_case();
        let help = Self::LONG_HELP_VARIANTS?
            .iter()
            .find(|v| &query_cased == v.0)?
            .1;
        Some(help)
    }
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
/// By default, it will create the types `CleanConfig` and `OptionConfig` in the module. Run with the optional flag `no_clean` in front to disable that.
#[macro_export]
macro_rules! config_struct {
    ($struct_name:tt, $config_struct_name:tt, $($(clap: $clap_flag:tt)* default: $default_value:expr, help: $help:expr, long_help: $long_help:expr, $field_name:tt: $field_type:ty),+$(,)?) => {
        config_struct!(no_clean $struct_name, $config_struct_name, $($(clap: $clap_flag)* default: $default_value, help: $help, long_help: $long_help, $field_name: $field_type),+);
        pub type CleanConfig = $struct_name;
        pub type OptionConfig = $config_struct_name;
        // use self::{CleanConfig, OptionConfig};
    };
    (no_clean $struct_name:tt, $config_struct_name:tt, $($(clap: $clap_flag:tt)* default: $default_value:expr, help: $help:expr, long_help: $long_help:expr, $field_name:tt: $field_type:ty),+$(,)?) => {
        #[derive(Debug, Clone, Serialize, Deserialize, SmartDefault)]
        pub struct $struct_name {
            $(
                #[default($default_value)]
                pub $field_name: $field_type,
            )+
        }
        impl crate::config::Configuration for $struct_name {
            type OverwriteWith = $config_struct_name;
            // const SHORT_HELP_VARIANTS: crate::config::HelpVariants = Some(&[
            //     $((const_format::map_ascii_case!(const_format::Case::Kebab, stringify!($field_name)), $help),)+
            // ]);
            config_struct!(SHORT_HELP_VARIANTS, $($field_name, $help,)+);
            config_struct!(LONG_HELP_VARIANTS, $($field_name, $long_help,)+);
            fn overwrite_with(&mut self, overwrite_with: Self::OverwriteWith) {
                $(
                    if let Some(f) = overwrite_with.$field_name {
                        self.$field_name = f
                    }
                )+
            }
            // fn get_help(&self, query: &str) -> &'static str {
            //     for
            // }
        }
        #[derive(Debug, Parser, Clone, Serialize, Deserialize, Default)]
        pub struct $config_struct_name {
            $(
                #[arg($($clap_flag,)* long, help = $help, long_help = $long_help)]
                pub $field_name: Option<$field_type>,
            )+
        }
    };
    ($constant:tt, $($field_name:tt, $help_variant:expr),+$(,)?) => {
        const $constant: crate::config::HelpVariants = Some(&[
            $((::const_format::map_ascii_case!(::const_format::Case::Kebab, stringify!($field_name)), $help_variant),)+
        ]);
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
            const SHORT_HELP_VARIANTS: crate::config::HelpVariants = None;
            const LONG_HELP_VARIANTS: crate::config::HelpVariants = None;
            fn overwrite_with(&mut self, overwrite_with: Self::OverwriteWith) {
                $(
                    if let Some(f) = overwrite_with.$key {
                        self.$key.overwrite_with(f)
                    }
                )+
            }
        }
        #[derive(Parser, Debug, Default, Serialize, Deserialize)]
        #[command(name = NAME, author = AUTHOR, version = env!("CARGO_PKG_VERSION"), about = env!("CARGO_PKG_DESCRIPTION"), long_about = None)]
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
    config_paths: (CleanConfig, OptionConfig),

    - #[arg(skip)]
    modules: (modules::CleanConfig, modules::OptionConfig),

    - #[command(flatten)]
    disks: (modules::disks::CleanConfig, modules::disks::OptionConfig),
    - #[command(flatten)]
    memory: (modules::memory::CleanConfig, modules::memory::OptionConfig),
    - #[command(flatten)]
    cpu: (modules::cpu::CleanConfig, modules::cpu::OptionConfig),
    - #[command(flatten)]
    time: (modules::time::CleanConfig, modules::time::OptionConfig),
    - #[command(flatten)]
    weather: (modules::weather::CleanConfig, modules::weather::OptionConfig),
    ~ #[serde(skip)]
    - #[command(flatten)]
    verbose: (Verbosity, VerbosityOptions),
}
impl Config {
    /// Create a new instance, first parsing args, then loading the config file
    #[tracing::instrument(skip_all, level = "debug")]
    pub fn new() -> Self {
        let config_start = ConfigPartial::parse();

        let default_config_path = config_path();

        // make sure there is always an example -- it's better than trying to read it twice or something stupid like that
        if !default_config_path.exists() {
            match Self::write_example_config() {
                Ok(_) => info!(
                    "Wrote new example config to {}",
                    default_config_path.display()
                ),
                Err(e) => error!("Could not write example config: {}", e),
            }
        }

        let mut default_config = Self::default();

        let system_config = Path::new("/etc/hbar/config.toml");

        if let Ok(c) = ConfigPartial::from_file(system_config) {
            default_config.overwrite_with(c)
        }

        if let Ok(c) = ConfigPartial::from_file(&default_config_path) {
            default_config.overwrite_with(c)
        }

        // overwrite with arg-provided config path last in the file hierarchy
        if let Some(p) = &config_start.config_paths {
            if let Some(f) = &p.config_file {
                match ConfigPartial::from_file(f) {
                    Ok(c) => {
                        info!("Overriding config file path with: {}", f.display());
                        default_config.overwrite_with(c);
                    }
                    Err(e) => error!("Could not read config file: {}", e),
                }
            }
        }

        // overwrite with the args last, because I want to override everything
        default_config.overwrite_with(config_start);

        default_config
    }
    /// Write the example config, synchronously
    #[tracing::instrument(skip_all, level = "debug")]
    pub fn write_example_config() -> ModResult<()> {
        let default_config = Self::default();
        let conf_path = &default_config.config_paths.config_file;

        let serialized = toml_edit::ser::to_string_pretty(&default_config)?;

        // TODO: Add documentation into the config file

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
    #[tracing::instrument(skip_all, level = "debug")]
    pub fn from_file(filepath: &Path) -> ModResult<Self> {
        let string_config = std::fs::read_to_string(filepath)?;
        let config_struct = toml_edit::de::from_str::<Self>(&string_config)?;
        Ok(config_struct)
    }
}

macro_rules! home {
    () => {
        dirs::home_dir()
            .expect("Could not find $HOME")
            .join(concatcp!(".", NAME))
    };
}

config_struct! {
    ConfigDirs, ConfigDirsOptions,

    clap: short
    default: config_path(),
    help: "Override the config file",
    long_help: "Override the config file",
    config_file: PathBuf,

    default: runtime_path(),
    help: "Override the runtime directory",
    long_help: "Override the runtime directory",
    runtime_path: PathBuf,
}

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

// gotta have the verbosity flag
config_struct! { no_clean
    Verbosity, VerbosityOptions,

    clap: short
    default: LogLevel::default(),
    help: "Log level",
    long_help: "Choose the log level. Trace is a little buggy right now, sorry :(",
    log_level: LogLevel,
}

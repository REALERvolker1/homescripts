use crate::*;

use clap::Parser;

#[derive(Parser, Debug, Default, Serialize, Deserialize)]
#[command(author, version, about, long_about = None)]
pub struct Config {
    // #[arg(short, long, help = "Override the config file", default_value_os_t = config_path())]
    // #[serde(skip)]
    // pub config_file: PathBuf,

    // #[arg(long, help = "Override the runtime directory", default_value_os_t = runtime_path())]
    // #[serde(skip)]
    // pub runtime_path: PathBuf,
    #[serde(skip)]
    #[command(flatten)]
    pub config_paths: ConfigDirs,

    #[arg(skip)]
    pub modules: modules::ModuleConfig,

    #[command(flatten)]
    pub battery: modules::battery::BatteryConfig,
    #[command(flatten)]
    pub memory: modules::memory::MemoryConfig,
    #[command(flatten)]
    pub cpu: modules::cpu::CpuConfig,
    #[command(flatten)]
    pub disks: modules::disks::DiskConfig,
    #[command(flatten)]
    pub time: modules::time::Time,
    #[command(flatten)]
    pub weather: modules::weather::Weather,

    #[serde(skip)]
    #[command(flatten)]
    pub verbose: Verbosity<WarnLevel>,
}
impl Config {
    pub async fn get_example_config(&self) -> ModResult<String> {
        let new_self = Config::default();
        let serialized = toml::to_string_pretty(&new_self)?;

        Ok(serialized)
    }
}
impl fmt::Display for Config {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match toml::to_string_pretty(&self) {
            Ok(s) => write!(f, "{}", s),
            Err(e) => write!(f, "{:?}", e),
        }
    }
}

macro_rules! home {
    () => {
        dirs::home_dir()
            .expect("Could not find $HOME")
            .join(concatcp!(".", NAME))
    };
}

#[derive(Parser, Debug, Clone, SmartDefault, Serialize, Deserialize)]
pub struct ConfigDirs {
    #[arg(long, help = "Override the config file", default_value_os_t = Self::config_path())]
    #[default(Self::config_path())]
    pub config_file: PathBuf,
    #[arg(long, help = "Override the runtime directory", default_value_os_t = Self::runtime_path())]
    #[default(Self::runtime_path())]
    pub runtime_path: PathBuf,
    // #[arg(long, help = "Override the log file path", default_value_os_t = Self::log_dir())]
    // #[default(Self::log_dir())]
    // pub log_dir: PathBuf,
}
impl ConfigDirs {
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

    // /// Get the path to the log directory.
    // fn log_dir() -> PathBuf {
    //     dirs::cache_dir()
    //         .unwrap_or(home!().join("cache"))
    //         .join(NAME)
    //         .join("logs")
    // }
}

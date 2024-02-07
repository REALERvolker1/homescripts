use crate::*;

/// The config for the program
///
/// Please please PLEASE add a way to enable or disable each module, even if there is no config.
#[derive(Debug, SmartDefault, Deserialize, Serialize)]
pub struct Config {
    #[default(runtime_path())]
    pub runtime_path: PathBuf,

    pub modules: modules::ModuleConfig,

    pub battery: modules::battery::BatteryConfig,
    pub memory: modules::memory::MemoryConfig,
    pub cpu: modules::cpu::CpuConfig,
    pub disks: modules::disks::DiskConfig,
    pub time: modules::time::Time,
    pub weather: modules::weather::Weather,

    pub requires_dbus: bool,
}
impl Config {
    /// TODO: Read config file
    pub async fn new() -> ModResult<Self> {
        Ok(Self::default())
    }

    pub async fn get_example_config(&self) -> ModResult<String> {
        let serialized = toml::to_string_pretty(&self)?;

        Ok(serialized)
    }
}

macro_rules! home {
    () => {
        dirs::home_dir().expect("Could not find $HOME")
    };
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
        .unwrap_or(dirs::cache_dir().unwrap_or(home!().join(".runtime")))
        .join(NAME)
}

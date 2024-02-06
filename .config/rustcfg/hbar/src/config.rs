use crate::*;

#[derive(Debug, SmartDefault, Deserialize, Serialize)]
pub struct Config {
    #[default(config_path())]
    pub config_path: PathBuf,

    pub battery: modules::battery::BatteryConfig,
    pub sysinfo: modules::system_info::SystemInfoConfig,
    pub time: modules::time::Time,
    pub weather: modules::weather::Weather,

    pub requires_dbus: bool,
}
impl Config {
    pub async fn new() -> ModResult<Self> {
        Ok(Self::default())
    }
}

/// Get the path to the config file. This panics if it can't find any of the other directory options and your `$HOME` variable is not set.
fn config_path() -> PathBuf {
    let config_dir = if let Ok(d) = env::var(CONFIG_OVERRIDE) {
        PathBuf::from(d)
    } else if let Ok(d) = env::var("XDG_CONFIG_HOME") {
        PathBuf::from(d).join(NAME)
    } else {
        PathBuf::from(env::var("HOME").unwrap())
            .join(format_args!(".config/{}", NAME).as_str().unwrap())
    };

    config_dir.join("config.toml")
}

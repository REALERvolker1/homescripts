use log::{debug, info, trace, warn};
use smart_default::SmartDefault;

#[derive(Debug, Default)]
pub struct Config {
    /// The representation of pacman.conf
    pub pacman: pacmanconf::Config,
    pub alpm: Option<alpm::Alpm>,
    pub aur_handle: Option<raur::Handle>,
}
impl Config {
    pub fn new(is_alpm: bool, is_aur: bool) -> eyre::Result<Self> {
        let pacman_config = pacmanconf::Config::new()?;

        let alpm = if is_alpm {
            info!("Creating `ALPM` instance");
            Some(alpm::Alpm::new(
                pacman_config.root_dir.as_str(),
                pacman_config.db_path.as_str(),
            )?)
        } else {
            None
        };

        let aur_handle = if is_aur {
            info!("Creating `raur` handle");
            Some(raur::Handle::new())
        } else {
            None
        };

        Ok(Self {
            pacman: pacman_config,
            alpm,
            aur_handle,
        })
    }
}

// pub fn new() -> eyre::Result<()> {
//     let config = pacmanconf::Config::new()?;
//     // println!("cache: {}", config.root_dir);
//     alpm::Alpm::new(root, db_path)

//     Ok(())
// }

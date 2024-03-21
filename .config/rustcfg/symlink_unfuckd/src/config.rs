use crate::BIN;
use ahash::{HashSet, HashSetExt};
use inotify::{Inotify, WatchMask};
use std::{env, fs, io, panic, path::PathBuf};
use tracing::{error, info, warn};

const WATCHMASK: WatchMask = WatchMask::CREATE;

#[derive(Debug, Default)]
pub struct WatchConfig {
    direct_paths: Vec<PathBuf>,
    watch_dirs: Option<Vec<PathBuf>>,
}
impl WatchConfig {
    pub fn new<I: IntoIterator<Item = PathBuf>>(paths: I) -> Self {
        let mut watch_dirs = HashSet::new();
        let mut direct_paths = HashSet::new();

        for path in paths.into_iter() {
            let Some(parent) = path.parent() else {
                error!("Skipping watchpath, no parent: {}", path.display());
                continue;
            };
            if !parent.exists() {
                error!(
                    "Skipping watchpath, parent does not exist: {}",
                    parent.display()
                );
                continue;
            }

            watch_dirs.insert(parent.to_path_buf());
            direct_paths.insert(path);
        }

        Self {
            direct_paths: direct_paths.into_iter().collect(),
            watch_dirs: Some(watch_dirs.into_iter().collect()),
        }
    }
    /// Parses args, reads config file, creates inotify object. This moves the watch dirs out of self, to conserve memory.
    pub fn init_inotify(&mut self) -> io::Result<Inotify> {
        let inotify = Inotify::init()?;
        let Some(watch_dirs) = self.watch_dirs.take() else {
            return Ok(inotify);
        };

        for path in watch_dirs {
            if path.exists() {
                inotify.watches().add(path, WATCHMASK)?;
            } else {
                warn!("Skipping, path does not exist: {}", path.display());
            }
        }

        Ok(inotify)
    }
    pub fn rm_symlinks(&self) {
        self.direct_paths
            .iter()
            .filter(|p| p.is_symlink())
            .for_each(|p| match fs::remove_file(p) {
                Ok(_) => info!("Removed link: {}", p.display()),
                Err(e) => error!("Failed to remove link: {} {}", p.display(), e),
            });
    }
}

pub fn get_filepaths() -> io::Result<WatchConfig> {
    let mut opt_config_path = None;

    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--config" => {
                if let Some(maybe_config) = args.next() {
                    let c = PathBuf::from(maybe_config);
                    if c.is_file() {
                        opt_config_path = Some(c);
                    } else {
                        panic_help(format_args!("Invalid config path: {}", c.display()));
                    }
                } else {
                    panic_help(format_args!("No config path provided!"));
                }
            }
            _ => panic_help(format_args!("Invalid arg: {arg}")),
        }
    }

    let config_path = opt_config_path.unwrap_or_else(|| {
        let config_path = default_config_path();
        info!("Using default config path: {}", config_path.display());
        config_path
    });

    info!("Loading config file: {}", config_path.display());

    let home: PathBuf = env::var_os("HOME")
        .unwrap_or_else(|| {
            panic!("Could not find home directory! (is $HOME set?)");
        })
        .into();
    let config_file = std::fs::read_to_string(&config_path)?;

    let paths = config_file
        .lines()
        .map(|l| l.trim())
        .filter(|l| !l.starts_with('#'))
        .filter(|l| !l.is_empty())
        .map(|l| {
            if let Some(stripped) = l.strip_prefix("~/") {
                home.join(stripped)
            } else {
                PathBuf::from(l)
            }
        });

    let watch = WatchConfig::new(paths);

    Ok(watch)
}

fn default_config_path() -> PathBuf {
    let config_home = env::var_os("XDG_CONFIG_HOME").unwrap_or_else(|| {
        warn!("XDG_CONFIG_HOME not set, falling back to $HOME/.config");
        let cfg = env::var("HOME").unwrap_or_else(|_| {
            panic!("Could not find home directory! (is $HOME set?)");
        }) + "/.config";

        cfg.into()
    });

    // apparently better than all those .join() allocations
    let mut config_path = PathBuf::from(config_home);

    config_path.push(env!("CARGO_PKG_NAME"));
    config_path.push("config");

    config_path
}

fn panic_help(error: std::fmt::Arguments<'_>) {
    println!("Usage: {BIN} [--config <path>]
Available options:

--config <path>     Path to an alternative config file. Defaults to {}

The config path is a newline separated list of paths to watch with inotify. Please see inotify(7) for how this works.", default_config_path().display());
    panic!("{error}");
}

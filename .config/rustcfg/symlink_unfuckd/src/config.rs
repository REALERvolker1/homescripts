use crate::BIN;
use futures_util::{FutureExt, StreamExt, TryFutureExt, TryStreamExt};
use inotify::{Inotify, WatchMask};
use std::{
    env, panic,
    path::{Path, PathBuf},
};
use tokio::{fs, io};
use tracing::{debug, error, info, warn};

const WATCHMASK: WatchMask = WatchMask::CREATE;

#[derive(Debug, Default)]
pub struct WatchConfig {
    direct_path_files: Vec<PathBuf>,
    direct_path_dirs: Vec<PathBuf>,
    dirs: Vec<PathBuf>,
}
impl WatchConfig {
    pub fn new<I: IntoIterator<Item = PathBuf>>(direct_paths: I, dirs: I) -> Self {
        let mut me = Self::default();

        for path in direct_paths.into_iter() {
            if path.is_dir() {
                me.direct_path_dirs.push(path);
            } else if path.is_file() {
                me.direct_path_files.push(path);
            } else {
                error!("Skipping, not a file or dir: {}", path.display());
            }
        }

        for dir in dirs.into_iter() {
            if dir.is_dir() {
                me.dirs.push(dir);
            } else {
                error!("Skipping watchdir, not a dir: {}", dir.display());
            }
        }

        me
    }
    /// Get this as an iterator, sorted folders before files
    pub fn as_ref_iter(&self) -> impl Iterator<Item = &Path> {
        self.direct_path_dirs
            .iter()
            .map(|f| f.as_path())
            .chain(self.direct_path_files.iter().map(|f| f.as_path()))
    }
    /// Parses args, reads config file, creates inotify object
    pub fn init_inotify(&self) -> io::Result<Inotify> {
        let inotify = Inotify::init()?;
        for path in self.dirs.iter() {
            if path.exists() {
                inotify.watches().add(&path, WATCHMASK)?;
            } else {
                warn!("Skipping, path does not exist: {}", path.display());
            }
        }

        Ok(inotify)
    }
    pub async fn rm_symlinks(&self) -> io::Result<()> {
        let dir_read_futures = self
            .dirs
            .iter()
            .map(|d| fs::read_dir(d).map_ok(tokio_stream::wrappers::ReadDirStream::new));
        let read_dir_streams = futures_util::future::join_all(dir_read_futures)
            .await
            .into_iter()
            .filter_map(|f| f.ok());

        let mut read_dir_stream = futures_util::stream::select_all(read_dir_streams);

        // set up files next, so I can do a funny little join! macro thing later to make it a little faster

        Ok(())
    }
}

// .map(|read_dir| async {
//             let mut links = Vec::new();
//             while let Some(res) read_dir.next().await {
//                 match res {
//                 Ok(Some(e)) => Some(e),
//                 Ok(None) => break,
//                 Err(e) => {
//                     error!("Failed to get direntry: {}", e);
//                     None
//                 }
//             }
//             }
//         });

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

    let paths = std::fs::read_to_string(config_path)?
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

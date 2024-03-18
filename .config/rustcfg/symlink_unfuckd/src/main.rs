use futures_util::StreamExt;
use inotify::{Inotify, WatchMask};
use once_cell::sync::Lazy;
use std::{
    env,
    panic::{self, PanicInfo},
    path::{Path, PathBuf},
    process::exit,
};
use tokio::{
    fs, io,
    signal::unix::{self, SignalKind},
};
use tracing::{debug, error, info, warn, Level};
use tracing_subscriber::fmt::format::FmtSpan;

/// My lockfile path, in a place that all areas can access. I couldn't make it in an rc because the panic handler
static LOCKFILE: Lazy<PathBuf> = Lazy::new(|| env::temp_dir().join(BIN.to_owned() + ".lock"));

const BIN: &str = env!("CARGO_PKG_NAME");

const WATCHMASK: WatchMask = WatchMask::CREATE;

#[cfg(not(debug_assertions))]
const LOG_LEVEL: Level = Level::INFO;

#[cfg(debug_assertions)]
const LOG_LEVEL: Level = Level::DEBUG;

#[cfg(target_os = "linux")]
fn main() -> io::Result<()> {
    tracing_subscriber::FmtSubscriber::builder()
        .compact()
        .with_max_level(LOG_LEVEL)
        .with_level(true)
        .with_span_events(FmtSpan::EXIT)
        .with_writer(std::io::stderr)
        .init();
    panic::set_hook(Box::new(|i| {
        error!("{i}");
        exit(3);
    }));

    if LOCKFILE.exists() {
        panic!("Lockfile already exists: {}", LOCKFILE.display());
    }

    let inotify = init_inotify()?;
    let buffer = [0u8; 4096];

    tokio::runtime::Builder::new_current_thread()
        .enable_io()
        .build()?
        .block_on(async {
            lock().await?;

            let mut events = inotify.into_event_stream(buffer)?;

            while let Some(e) = events.next().await {
                match e {
                    Ok(e) => {
                        info!("{:?} Event: {:?}", WATCHMASK, e);
                    }
                    Err(e) => error!("Error: {e}"),
                }
            }

            Ok::<(), io::Error>(())
        })?;

    Ok(())
}

// async fn remove_symlinks(path: &Path) -> io::Result<()>

fn unlock() {
    match std::fs::remove_file(LOCKFILE.as_path()) {
        Ok(_) => info!("Unlocked lockfile"),
        Err(e) => error!("Failed to unlock lockfile: {e}"),
    }
}

async fn lock() -> io::Result<()> {
    fs::File::create(LOCKFILE.as_path()).await?;
    panic::set_hook(Box::new(|info| {
        unlock();

        error!("{info}");
        exit(127);
    }));

    // reminder: this must be called after setting panic handler because unwrap
    tokio::task::spawn(async move {
        let mut sigterm = unix::signal(SignalKind::terminate()).unwrap();
        let mut sigint = unix::signal(SignalKind::interrupt()).unwrap();
        let mut sigquit = unix::signal(SignalKind::quit()).unwrap();

        loop {
            tokio::select! {
                _ = sigterm.recv() => {
                    unlock();
                    warn!("Received SIGTERM");
                }
                _ = sigint.recv() => {
                    unlock();
                    warn!("Received SIGINT");
                }
                _ = sigquit.recv() => {
                    unlock();
                    debug!("Received SIGQUIT"); // normal exit process
                }
            }
        }
    });

    Ok(())
}

pub fn get_filepaths() -> io::Result<Vec<PathBuf>> {
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

    let home: once_cell::unsync::Lazy<String> = once_cell::unsync::Lazy::new(|| {
        env::var("HOME")
            .unwrap_or_else(|_| {
                panic!("Could not find home directory! (is $HOME set?)");
            })
            .into()
    });

    std::fs::read_to_string(config_path)?.lines().map(|l| l.trim())
        // ignore comments
        let line = line.trim();
        if line.starts_with('#') || line.is_empty() {
            continue;
        }

        // .replace makes a string so I kinda just thought wth lets do it this way
        let path = if line.starts_with('~') {
            line.replace("~", &home).into()
        } else {
            PathBuf::from(line)
        };

        debug!("Adding watch: {}", path.display());
    }

    Ok(inotify)
}

/// Parses args, reads config file, creates inotify object
pub fn init_inotify<I: Iterator<Item = Path>>(paths: I) -> io::Result<Inotify> {
    let inotify = Inotify::init()?;
    for path in paths {
        if path.exists() {
            inotify.watches().add(path, WATCHMASK)?;
        } else {
            warn!("Skipping, path does not exist: {}", path.display());
        }
    }

    Ok(inotify)
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

#[inline]
fn panic_help(error: std::fmt::Arguments<'_>) {
    println!("Usage: {BIN} [--config <path>]
Available options:

--config <path>     Path to an alternative config file. Defaults to {}

The config path is a newline separated list of paths to watch with inotify. Please see inotify(7) for how this works.", default_config_path().display());
    panic!("{error}");
}

/*
#[cfg(target_os = "linux")]
fn oldmain() -> io::Result<()> {
    if LOCKFILE.exists() {
        panic!("Lockfile already exists: {}", LOCKFILE.display());
    }

    // argparsing

    // I use a vec here because inotify `Watches` object has no way to see if I have any watches or not.
    let mut watch_files = Vec::new();

    for arg in env::args().skip(1) {
        let filepath = PathBuf::from(arg);
        if filepath.is_dir() {
            println!("[{}] Adding watch: {}\n", BIN, filepath.display());
            watch_files.push(filepath)
        } else {
            println!(
                "Usage: {BIN} /path/to/folder1 /path/to/folder2

All paths must be folders.
All symlinks in these folders will be removed as soon as they are created.

Invalid path: {}",
                filepath.display()
            );
            std::process::exit(2);
        }
    }

    if watch_files.is_empty() {
        panic!("No watch files provided! Please run with arg --help for more information.");
    }

    // deal with lockfile

    let mut signals = signal_hook::iterator::Signals::new(&[
        signal_hook::consts::SIGINT,
        signal_hook::consts::SIGTERM,
        signal_hook::consts::SIGABRT,
    ])
    .unwrap();

    std::panic::set_hook(Box::new(|info| {
        match fs::remove_file(LOCKFILE.as_path()) {
            Ok(_) => println!("Lockfile removed"),
            Err(e) => println!("Failed to remove lockfile: {e}"),
        }

        println!("[{BIN}] {info}");

        std::process::exit(127);
    }));

    fs::File::create(LOCKFILE.as_path())?;

    thread::spawn(move || {
        println!("[{BIN}] Started signal handler");
        for sig in signals.forever() {
            panic!(
                "[{BIN}] Received signal: {}",
                signal_hook::low_level::signal_name(sig).unwrap_or_default()
            );
        }
    });

    // the main inotify loop

    let mut ntfy = inotify::Inotify::init()?;
    let mask = inotify::WatchMask::CREATE;

    for dir in watch_files.iter() {
        ntfy.watches().add(dir, mask)?;
    }

    let mut buffer = [0u8; 4096];

    loop {
        let events = ntfy.read_events_blocking(&mut buffer)?;

        for event in events {
            watch_files
                .iter()
                .filter_map(|d| d.read_dir().ok())
                .flatten()
                .filter_map(|d| d.ok())
                .map(|d| d.path())
                .filter(|d| d.is_symlink())
                .filter(|d| d.is_file())
                .for_each(|d| match fs::remove_file(&d) {
                    Ok(_) => println!("[{BIN}] Removed link: {}", d.display()),
                    Err(e) => println!("[{BIN}] Failed to remove link: {e}"),
                });

            if let Some(name) = event.name {
                println!("[{BIN}] Event: {}", name.to_string_lossy());
            }
        }
    }
}
*/

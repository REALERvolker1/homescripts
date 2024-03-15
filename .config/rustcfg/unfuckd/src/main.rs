use once_cell::sync::Lazy;
use std::{
    env, fs,
    io::{self, Write},
    path::{Path, PathBuf},
    thread,
};

/// My lockfile path, in a place that all areas can access. I couldn't make it in an rc because the panic handler
static LOCKFILE: Lazy<PathBuf> = Lazy::new(|| env::temp_dir().join(BIN.to_owned() + ".lock"));

const BIN: &str = env!("CARGO_PKG_NAME");

#[cfg(target_os = "linux")]
fn main() -> io::Result<()> {
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

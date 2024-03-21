use crate::BIN;

use once_cell::sync::Lazy;
use std::{env, fs, io, panic, path::PathBuf, process::exit};

use tracing::{error, info};

/// My lockfile path, in a place that all areas can access.
static LOCKFILE: Lazy<PathBuf> = Lazy::new(|| env::temp_dir().join(BIN.to_owned() + ".lock"));

/// Check if the lockfile is locked. Panic if it is.
pub fn check_locked() {
    if LOCKFILE.exists() {
        panic!("Lockfile already exists: {}", LOCKFILE.display());
    }
}

pub fn unlock() {
    match std::fs::remove_file(LOCKFILE.as_path()) {
        Ok(_) => info!("Unlocked lockfile"),
        Err(e) => error!("Failed to unlock lockfile: {e}"),
    }
}

/// Locks the lockfile, creating it and then setting a panic handler that unlocks it when it panics.
pub fn lock() -> io::Result<()> {
    fs::File::create(LOCKFILE.as_path())?;

    panic::set_hook(Box::new(|info| {
        unlock();

        error!("{info}");
        exit(127);
    }));

    Ok(())
}

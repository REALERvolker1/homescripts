use crate::BIN;

use once_cell::sync::Lazy;
use std::{env, panic, path::PathBuf, process::exit};
use tokio::{
    fs, io,
    signal::unix::{self, SignalKind},
};
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

pub async fn lock() -> io::Result<()> {
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

        tokio::select! {
            _ = sigterm.recv() => {
                panic!("Received SIGTERM");
            }
            _ = sigint.recv() => {
                panic!("Received SIGINT");
            }
            _ = sigquit.recv() => {
                panic!("Received SIGQUIT"); // normal exit process
            }
        }
    });

    Ok(())
}

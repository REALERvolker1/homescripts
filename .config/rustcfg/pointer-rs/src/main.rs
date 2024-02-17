//! TODO: Implemnt Xorg backend

mod config;
mod hypr;
mod types;
mod udev;

pub(crate) use ahash::{HashSet, HashSetExt};

pub(crate) use futures_lite::StreamExt;
pub(crate) use types::*;
// pub(crate) use parking_lot::Mutex;
pub(crate) use color_eyre::eyre::anyhow;
pub(crate) use serde::{Deserialize, Serialize};
pub(crate) use std::{
    path::{Path, PathBuf},
    sync::Arc,
};
use tokio::io::AsyncWriteExt;
pub(crate) use tokio::sync::mpsc::{self, Sender};

pub type Res<T> = color_eyre::Result<T>;

lazy_static::lazy_static! {
    pub static ref CONFIG: config::Config = config::Config::new();
}

fn main() -> Res<()> {
    color_eyre::install()?;
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?
        .block_on(async move { CONFIG.command.run().await.unwrap() });

    Ok(())
}

#[allow(async_fn_in_trait)]
/// Shared methods and types that all backends must implement.
pub trait Backend: Sized + std::fmt::Debug + std::fmt::Display {
    async fn new() -> Res<Self>;
    /// Get the current backend type. Should kinda just be a static.
    fn backend() -> Backends;

    /// Refresh this list with mice. This is meant to be used internally.
    fn refresh_with_mice(&mut self, mice: Vec<Mouse>);
    /// Refresh the list of mice connected that are in `CONFIG.mouse_identifiers`
    async fn refresh_mice(&mut self) -> Res<()> {
        let pointers = Self::raw_get_pointers().await?.into_iter().collect();
        self.refresh_with_mice(pointers);
        Ok(())
    }
    /// Just get all the pointer devices
    async fn raw_get_pointers() -> Res<Vec<Mouse>>;
    async fn get_touchpad_status(&self) -> Res<Status>;
    async fn set_touchpad_status(&self, status: Status) -> Res<()>;

    /// This is "blocking", it monitors the udev status and updates the icon file
    async fn status_monitor_inner(&mut self) -> Res<()>;

    fn has_mice(&self) -> bool;
}

impl config::Command {
    pub async fn run(&self) -> Res<()> {
        let mut backend = CONFIG.backend.new_backend_thing().await?;

        eprintln!("{:?}", backend);

        match self {
            Self::GetStatus => {
                let status = backend.get_touchpad_status().await?;
                println!("{}", status);
            }
            Self::GetIcon => {
                let status = backend.get_touchpad_status().await?;
                println!("{}", status.icon());
            }
            Self::Enable => {
                backend.set_touchpad_status(Status::On).await?;
            }
            Self::Disable => {
                backend.set_touchpad_status(Status::Off).await?;
            }
            Self::Toggle => {
                let current = backend.get_touchpad_status().await?;
                backend.set_touchpad_status(current.toggle()).await?;
            }
            Self::Normalize => {
                let current = Status::from_bool(backend.has_mice());
                backend.set_touchpad_status(current.toggle()).await?;
            }
            Self::StatusMonitor => {
                let (sender, mut receiver) = mpsc::channel(5);

                tokio::spawn(async move {
                    // asynchronously write to stderr, because I need less latency
                    let mut stderr = tokio::io::stderr();
                    loop {
                        backend.status_monitor_inner().await.unwrap();
                        let back_display = backend.to_string();

                        let (write, recv) =
                            tokio::join!(stderr.write(back_display.as_bytes()), receiver.recv());

                        write.unwrap();
                        if recv.is_none() {
                            panic!("Status monitor stream ended");
                        }
                    }
                });

                // udev here reeeally doesn't like being in separate tokio tasks
                udev::monitor_devices(sender).await?;
            }
            Self::MonitorIcon => {
                let _ = backend.get_touchpad_status().await?;
                let listener = inotify::Inotify::init()?;
                listener
                    .watches()
                    .add(&CONFIG.touchpad_statusfile, inotify::WatchMask::MODIFY)?;

                let mut buffer = [0; 1024];
                let mut stream = listener.into_event_stream(&mut buffer)?;

                let timeout = std::time::Duration::from_secs(1);
                let mut stdout = tokio::io::stdout();

                let mut timeout_count: u8 = 0;

                loop {
                    match CONFIG.read_statusfile().await {
                        Ok(s) => {
                            let output = s + "\n";
                            stdout.write(&output.as_bytes()).await?;
                        }
                        Err(e) => {
                            timeout_count += 1;
                            // if the file is deleted or something, I give it 5 seconds to come back before ditching.
                            if timeout_count >= 30 {
                                return Err(e.into());
                            }
                            tokio::time::sleep(timeout).await;
                        }
                    }
                    if stream.next().await.is_none() {
                        eprintln!("Icon monitor stream ended");
                        std::process::exit(127);
                    }
                }
            }

            _ => unreachable!(),
        }

        Ok(())
    }
}

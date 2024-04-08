//! TODO: Implemnt Xorg backend

mod config;
mod hypr;
mod types;

pub(crate) use ahash::{HashSet, HashSetExt};
pub(crate) use futures_util::StreamExt;
pub(crate) use serde::{Deserialize, Serialize};
pub(crate) use simple_eyre::eyre::eyre;
pub(crate) use std::{
    fmt,
    path::{Path, PathBuf},
};
pub(crate) use tokio::io::AsyncWriteExt;
pub(crate) use types::*;

// lazy_static::lazy_static! {
//     pub static ref CONFIG: config::Config = config::Config::new();
// }

fn main() -> Res<()> {
    simple_eyre::install()?;
    let config = config::Config::new();
    tokio::runtime::Builder::new_current_thread()
        .enable_io()
        .build()?
        .block_on(async move {
            let comm = config.command;
            if let Err(e) = comm.run(config).await {
                eprintln!("Error: {}", e);
            }
        });

    Ok(())
}

#[allow(async_fn_in_trait)]
/// Shared methods and types that all backends must implement.
pub trait Backend: Sized + fmt::Debug {
    /// Create a new backend, consuming the Config
    async fn new(conf: Conf) -> Res<Self>;

    /// Just get all the pointer devices
    async fn raw_get_pointers() -> Res<Vec<Mouse>>;
    async fn get_touchpad_status(&self) -> Res<Status>;
    /// Set the touchpad status. Gets the status after setting.
    async fn set_touchpad_status(&self, status: Status) -> Res<Status>;

    /// Get the config
    fn conf(&self) -> &Conf;
    /// Get the current backend type. Should kinda just be a static.
    fn backend() -> Backends;
    /// Should check if the current mouse list is not empty
    fn has_mice(&self) -> bool;
    /// A getter for the internal mouse list
    fn cached_mice(&self) -> &MouseList;
    /// A setter for the internal mouse list
    fn set_mice(&mut self, mice: MouseList);
    /// A getter for the touchpad device
    fn touchpad(&self) -> &Mouse;

    /// Refresh this list with mice. This is meant to be used internally.
    fn refresh_with_mice(&mut self, mice: Vec<Mouse>) {
        let mice = mice
            .into_iter()
            .filter(|m| self.conf().is_mouse(&m.name))
            .filter(|m| &m.address != &self.touchpad().address)
            .map(|m| Mouse::from(m))
            .collect::<HashSet<_>>();

        self.set_mice(mice);
    }

    /// Refresh the list of mice connected that are in `CONFIG.mouse_identifiers`
    async fn refresh_mice(&mut self) -> Res<()> {
        let pointers = Self::raw_get_pointers().await?.into_iter().collect();
        self.refresh_with_mice(pointers);
        Ok(())
    }

    /// Toggle touchpad
    async fn toggle(&self) -> Res<()> {
        let current_status = self.get_touchpad_status().await?;
        let toggled_status = current_status.toggle();
        let new_status = self.set_touchpad_status(toggled_status).await?;
        if new_status == toggled_status {
            println!("Toggled touchpad from {current_status} to {new_status}");
            Ok(())
        } else {
            Err(eyre!(
                "Failed to toggle touchpad from {current_status} to {toggled_status}. Current status is {new_status}"
            ))
        }
    }

    /// I want my touchpad to be off when I have mice connected or something. Returns a Status to print.
    async fn normalize(&mut self, refresh_mice: bool) -> Res<Status> {
        if refresh_mice {
            self.refresh_mice().await?;
        }

        let status = if self.has_mice() {
            Status::Off
        } else {
            Status::On
        };

        let new_status = self.set_touchpad_status(status).await?;
        Ok(new_status)
    }

    /// Monitor the touchpad icon file using inotify
    async fn monitor_touchpad_icon(&mut self) -> Res<()> {
        // This requires the file to exist. If it does not exist, then it probably hasn't even been normalized yet.
        // It refreshes mice just in case it didn't already do that, for maximum unbreakage.
        if !self.conf().touchpad_statusfile.exists() {
            self.normalize(true).await?;
        }

        let listener = inotify::Inotify::init()?;
        listener
            .watches()
            .add(&self.conf().touchpad_statusfile, inotify::WatchMask::MODIFY)?;

        let second = std::time::Duration::from_secs(1);
        // if the file is deleted or something, I give it this many seconds to come back before just quitting.
        let timeout_seconds = 30;

        let mut buffer = [0; 1024];
        let mut stream = listener.into_event_stream(&mut buffer)?;
        // use async stdout
        let mut stdout = tokio::io::stdout();
        let mut timeout_count: u8 = 0;

        loop {
            // This loops until either the file is read successfully, or it times out.
            loop {
                match self.conf().read_statusfile().await {
                    Ok(s) => {
                        // let output = s + "\n";
                        stdout.write(&s.as_bytes()).await?;
                        timeout_count = 0;
                        // BREAK
                        break;
                    }
                    Err(e) => {
                        timeout_count += 1;
                        eprintln!("Timeout count: {timeout_count} on error {e}");

                        if timeout_count >= timeout_seconds {
                            // BREAK
                            return Err(eyre!("statusfile read timed out"));
                        }
                        tokio::time::sleep(second).await;
                    }
                }
            }
            if stream.next().await.is_none() {
                return Err(eyre!("inotify stream closed"));
            }
        }
    }
}

impl config::Command {
    pub async fn run(&self, conf: Conf) -> Res<()> {
        let backeend_type = conf.backend;
        let mut backend = backeend_type.new_backend_thing(conf).await?;

        match self {
            Self::GetStatus => {
                println!("{}", backend.get_touchpad_status().await?);
            }
            Self::GetIcon => {
                println!("{}", backend.get_touchpad_status().await?.icon());
            }
            Self::Enable => {
                println!(
                    "Set status to {}",
                    backend.set_touchpad_status(Status::On).await?
                );
            }
            Self::Disable => {
                println!(
                    "Set status to {}",
                    backend.set_touchpad_status(Status::Off).await?
                );
            }
            Self::Toggle => {
                backend.toggle().await?;
            }
            Self::Normalize => {
                println!(
                    "Normalized touchpad status to {}",
                    backend.normalize(false).await?
                );
            }
            Self::StatusMonitor => {
                let mut stderr = tokio::io::stderr();

                let socket = tokio_udev::MonitorBuilder::new()?
                    .match_subsystem_devtype("usb", "usb_device")?;
                let mut monitor: tokio_udev::AsyncMonitorSocket = socket.listen()?.try_into()?;

                let mut should_run = true;

                loop {
                    let ev = if should_run {
                        let print_string = match backend.normalize(true).await {
                            Ok(s) => format!(
                                "Mice: {}\nNormalizing status to {s}\n",
                                backend
                                    .cached_mice()
                                    .iter()
                                    .map(|m| m.to_string())
                                    .collect::<Vec<_>>()
                                    .join(", ")
                            ),
                            Err(e) => format!("{e}\n"),
                        };
                        let (_, ev) =
                            tokio::join!(stderr.write(print_string.as_bytes()), monitor.next());
                        ev
                    } else {
                        monitor.next().await
                    };

                    if let Some(e) = ev {
                        match e {
                            Ok(event) => match event.event_type() {
                                tokio_udev::EventType::Bind
                                | tokio_udev::EventType::Unbind
                                | tokio_udev::EventType::Unknown => should_run = true,
                                _ => should_run = false,
                            },
                            Err(e) => return Err(eyre!("Error in udev monitor: {e}")),
                        }
                    }
                }
            }
            Self::MonitorIcon => {
                backend.monitor_touchpad_icon().await?;
            }
            Self::Help => unreachable!(),
        }

        Ok(())
    }
}

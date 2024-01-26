use crate::{cli::Action, hypr, types::*, *};
use serde::{Deserialize, Serialize};
use std::{env, sync::Arc};
use tokio::{io::AsyncWriteExt, sync::mpsc};

impl config::Config {
    pub async fn monitor_status(&self) -> PNul {
        if CONFIG.is_locked() {
            return Err(PError::Locked);
        }
        self.normalize().await?;

        let (tx, mut rx) = mpsc::channel::<()>(5);
        let sender = Arc::new(tx);

        // I wanted to put this in the main thread and have the monitor in the task, believe me I tried.
        tokio::spawn(async move {
            let mut out = tokio::io::stderr();
            while rx.recv().await.is_some() {
                let stuff_result = CONFIG.normalize().await;
                if let Err(e) = stuff_result {
                    let estring = e.to_string() + "\n";
                    let _ = out.write(estring.as_bytes()).await;
                }
            }
        });
        udev::monitor_udev(Arc::clone(&sender)).await?;
        Ok(())
    }
    pub async fn toggle(&self) -> PResult<Status> {
        let my_status = self.get_status().await;
        if let Some(b) = my_status.toggle().to_bool() {
            self.set_status(b).await
        } else {
            Err(PError::Other(String::from(
                "Error, status is undefined, nothing changed.",
            )))
        }
    }
    /// Get the current status. Meant to be called from the command line.
    pub async fn get_status(&self) -> Status {
        match self.backend {
            Backend::Hyprland => hypr::hyprland_status(&self.hyprland_touchpad).await,
            Backend::Xorg => todo!(),
        }
    }
    /// set the status. Returns the new status
    pub async fn set_status(&self, enabled: bool) -> PResult<Status> {
        match self.backend {
            Backend::Hyprland => hypr::hyprland_set(&self.hyprland_touchpad, enabled).await?,
            Backend::Xorg => todo!(),
        }
        // little redundant here, but I want to double check, make sure I did this right.
        let current_status = self.get_status().await;
        current_status.update_iconfile(&self.lockfile.path).await?;
        eprintln!("Set pointer status to {}", current_status);
        Ok(current_status)
    }
    pub async fn normalize(&self) -> PResult<Status> {
        let res = self.set_status(!self.get_has_mice().await?).await?;

        Ok(res)
    }
    pub async fn get_has_mice(&self) -> PResult<bool> {
        Ok(match self.backend {
            Backend::Hyprland => {
                let mice = hypr::hyprland_get_mice_names().await?;
                !mice.is_empty()
            }
            Backend::Xorg => false,
        })
    }

    /// Don't use this function unless the code has gone to shit.
    pub async fn sync_status(&self) -> tokio::io::Result<()> {
        self.get_status()
            .await
            .update_iconfile(&self.lockfile.path)
            .await?;
        Ok(())
    }
    pub async fn exec(&self) -> PNul {
        match self.action {
            Action::Disable => {
                self.set_status(false).await?;
            }
            Action::Enable => {
                self.set_status(true).await?;
            }
            Action::Toggle => {
                self.toggle().await?;
            }
            Action::Normalize => {
                self.normalize().await?;
            }

            Action::GetIcon => {
                self.get_status().await.icon();
            }
            Action::GetStatus => {
                self.get_status().await;
            }

            Action::MonitorIcon => {
                self.lockfile.inotify().await?;
            }
            Action::StatusMonitor => {
                self.monitor_status().await?;
            }
            _ => unreachable!(),
        }
        Ok(())
    }
}

#[derive(
    Debug,
    Clone,
    Copy,
    Eq,
    Hash,
    PartialEq,
    strum_macros::Display,
    strum_macros::EnumIter,
    strum_macros::EnumIs,
    strum_macros::EnumString,
    Serialize,
    Deserialize,
)]
#[strum(serialize_all = "lowercase")]
pub enum Backend {
    Xorg,
    Hyprland,
}
impl Default for Backend {
    fn default() -> Self {
        Self::new().unwrap()
    }
}
impl Backend {
    /// Get a new instance of the backend type, or None if it is not implemented.
    pub fn new() -> Option<Self> {
        if env::var("HYPRLAND_INSTANCE_SIGNATURE").is_ok() {
            return Some(Self::Hyprland);
        } else if env::var("DISPLAY").is_ok() {
            return Some(Self::Xorg);
            // return None;
        }

        None
    }
    /// Just like `Backend::new()`, but will return an error if no backend is found.
    pub fn try_new() -> PResult<Self> {
        if let Some(s) = Self::new() {
            Ok(s)
        } else {
            Err(PError::from("Could not determine a suitable backend!"))
        }
    }
    pub fn keyify(&self, touchpad_name: &str) -> String {
        match self {
            Self::Hyprland => hypr::hyprland_keyword_touchpad_fmt(touchpad_name),
            Self::Xorg => touchpad_name.to_string(),
        }
    }
    pub async fn get_pointers(&self) -> PResult<Vec<String>> {
        Ok(match self {
            Backend::Hyprland => hypr::hyprland_get_mice_names().await?,
            Backend::Xorg => todo!(),
        })
    }
}

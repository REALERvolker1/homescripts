use super::*;
use crate::{ipc::*, types::*};
use futures::StreamExt;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use tracing::{debug, error, warn};
use zbus::zvariant::Type;
// https://gitlab.com/asus-linux/supergfxctl/-/blob/main/src/pci_device.rs?ref_type=heads
pub mod xmlgen;

pub struct SuperGfxModule<'a> {
    pub proxy: xmlgen::DaemonProxy<'a>,
    pub is_updating: bool,
    pub mode: GfxMode,
    pub power: GfxPower,
    pub status_stream: xmlgen::NotifyGfxStatusStream<'a>,
}
impl<'a> SuperGfxModule<'a> {
    fn icon(&self) -> Option<Icon> {
        match self.mode {
            GfxMode::Hybrid => match self.power {
                GfxPower::Active => Some('󰒇'),
                GfxPower::Suspended => Some('󰒆'),
                GfxPower::Off => Some('󰒅'),
                GfxPower::AsusDisabled => Some('󰒈'),
                GfxPower::AsusMuxDiscreet => Some('󰾂'),
                GfxPower::Unknown => None,
            },
            GfxMode::Integrated => Some('󰰃'),
            GfxMode::NvidiaNoModeset => Some('󰰒'),
            GfxMode::Vfio => Some('󰰪'),
            GfxMode::AsusEgpu => Some('󰯷'),
            GfxMode::AsusMuxDgpu => Some('󰰏'),
            GfxMode::None => Some('󰳤'),
        }
    }
}
impl FmtModule for SuperGfxModule<'_> {
    fn stdout(&self) -> String {
        if let Some(i) = self.icon() {
            i.to_string()
        } else {
            String::new()
        }
    }
    fn waybar(&self) -> String {
        let text = self.stdout();
        let power = self.power.to_string();
        let mode = self.mode.to_string();
        let class = if self.mode.is_watcher() {
            &power
        } else {
            &mode
        };
        let tooltip = format!("Mode: {}, Power: {}", &mode, &power);
        waybar_fmt(&text, &text, &tooltip, class, None)
    }
}
impl<'a> StaticModule for SuperGfxModule<'a> {
    #[inline]
    fn name(&self) -> &str {
        "SuperGFX"
    }
    fn mod_type(&self) -> ModuleType {
        if self.is_updating {
            ModuleType::DbusGetter
        } else {
            ModuleType::Static
        }
    }
    #[tracing::instrument(skip(self, server))]
    async fn update_server(&self, server: &dbus_server::ServerType) {
        let mut lock = server.lock().await;
        lock.supergfx(self).await;
        // lock.supergfxd_icon = self.icon();
    }
}
impl<'a> Module for SuperGfxModule<'a> {
    #[tracing::instrument(skip(connection))]
    async fn new(connection: &zbus::Connection) -> Result<Self, ModError> {
        let proxy = xmlgen::DaemonProxy::new(connection).await?;
        // I have to get the status stream anyways to satisfy the borrow checker
        let (mode, power, status_stream) = tokio::try_join!(
            proxy.mode(),
            proxy.power(),
            proxy.receive_notify_gfx_status()
        )?;
        let is_updating = mode.is_watcher();
        Ok(Self {
            proxy,
            is_updating,
            mode,
            power,
            status_stream,
        })
    }
    #[tracing::instrument(skip(self))]
    async fn update(&mut self, payload: RecvType) -> Result<(), ModError> {
        if payload.is_notify_status() {
            self.power = self.proxy.power().await?;
            Ok(())
        } else {
            let out = format!("SuperGFX Received unknown payload: '{:?}'", payload);
            warn!("{}", &out);
            Err(ModError::UpdateError(out))
        }
    }
    #[tracing::instrument(skip(self, server))]
    async fn run(&mut self, server: &dbus_server::ServerType) -> () {
        while self.status_stream.next().await.is_some() {
            // let _ = self.update(RecvType::NotifyStatus).await;
            if self.update(RecvType::NotifyStatus).await.is_ok() {
                self.update_server(server).await;
            }
        }
    }
    fn should_run(&self) -> bool {
        self.is_updating
    }
}
// impl ipc::IpcModule for SuperGfxModule<'_> {
//     async fn send_state(
//         &self,
//         interface: ipc::IpcType,
//         output_type: OutputType,
//     ) -> Result<(), ModError> {
//         let msg = match output_type {
//             OutputType::Waybar => self.waybar(),
//             OutputType::Stdout => self.stdout(),
//         };
//         let lock = interface.lock().await;
//         lock.send(&msg).await?;
//         Ok(())
//     }
// }

#[derive(
    Debug, Default, PartialEq, Eq, Copy, Clone, strum_macros::Display, Type, Serialize, Deserialize,
)]
pub enum GfxMode {
    Hybrid,
    Integrated,
    NvidiaNoModeset,
    Vfio,
    AsusEgpu,
    AsusMuxDgpu,
    #[default]
    None,
}
impl GfxMode {
    fn is_watcher(&self) -> bool {
        matches!(self, GfxMode::Hybrid)
    }
}

#[derive(
    Debug, Default, PartialEq, Eq, Copy, Clone, strum_macros::Display, Type, Serialize, Deserialize,
)]
pub enum GfxPower {
    Active,
    Suspended,
    Off,
    AsusDisabled,
    AsusMuxDiscreet,
    #[default]
    Unknown,
}

impl FromStr for GfxPower {
    type Err = ModError;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        debug!("Converting &str '{}' to GfxPower", s);
        match s {
            "active" => Ok(GfxPower::Active),
            "suspended" => Ok(GfxPower::Suspended),
            "off" => Ok(GfxPower::Off),
            "asus-disabled" => Ok(GfxPower::AsusDisabled),
            "asus-mux-discreet" => Ok(GfxPower::AsusMuxDiscreet),
            _ => {
                warn!("Could not convert '{}' to a known GfxPower type", s);
                Ok(GfxPower::Unknown)
            }
        }
    }
}
impl TryFrom<zbus::zvariant::OwnedValue> for GfxPower {
    type Error = ModError;
    fn try_from(value: zbus::zvariant::OwnedValue) -> Result<Self, Self::Error> {
        debug!(
            "Trying to convert from OwnedValue '{:?}' to GfxPower",
            value
        );
        if let Some(s) = value.downcast_ref::<str>() {
            let self_str = Self::from_str(s)?;
            Ok(self_str)
        } else {
            warn!("Could not convert '{:?}' to a known GfxPower type", value);
            Ok(Self::default())
        }
    }
}

/// Preferences for the supergfxctl status module (basically just nvidia optimus but better)
/// https://gitlab.com/asus-linux/supergfxctl
#[derive(Debug, SmartDefault, Serialize, Deserialize)]
pub struct SuperGfxConfig {
    /// Enable the module
    #[default(AutoBool::default())]
    enable: AutoBool,
}

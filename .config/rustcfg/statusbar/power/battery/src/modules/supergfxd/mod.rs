use crate::modules::*;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use tracing::{debug, info, warn};
use zbus::zvariant::Type;
// https://gitlab.com/asus-linux/supergfxctl/-/blob/main/src/pci_device.rs?ref_type=heads
pub mod xmlgen;

/// This is a stupid hack to work around Luke's asinine API.
/// He decided to implement types differently in the supergfxd dbus interface, so this is a workaround for that.
///
/// In some cases, the module does not have to update, since the GPU is either always on or always off.
/// In other cases, the module must update as usual.
pub struct SuperGfxPowerStream<'a> {
    inner: xmlgen::NotifyGfxStatusStream<'a>,
}
impl<'a> SuperGfxPowerStream<'a> {
    pub fn new(status_stream: xmlgen::NotifyGfxStatusStream<'a>) -> Self {
        Self {
            inner: status_stream,
        }
    }
}
impl<'a> futures::Stream for SuperGfxPowerStream<'a> {
    type Item = WeakStateType<'a>;
    fn poll_next(
        self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        if let std::task::Poll::Ready(Some(_)) = self.get_mut().inner.poll_next_unpin(cx) {
            std::task::Poll::Ready(Some(WeakStateType::SuperGFXPower))
        } else {
            std::task::Poll::Pending
        }
    }
}
#[tracing::instrument(skip(connection))]
pub async fn create_supergfxd_module<'a>(
    connection: &zbus::Connection,
) -> zbus::Result<(
    Option<xmlgen::DaemonProxy<'a>>,
    Option<SuperGfxPowerStream<'a>>,
    Icon<'a>,
)> {
    debug!("Trying to create supergfxd module");
    let daemon_connection = xmlgen::DaemonProxy::new(connection).await;
    let proxy = if let Ok(p) = daemon_connection {
        p
    } else {
        let e = daemon_connection.unwrap_err();
        warn!("Failed to connect to supergfxd: {}", e);
        return Err(e);
    };
    let (mode, status, status_stream) = tokio::try_join!(
        proxy.mode(),
        proxy.power(),
        proxy.receive_notify_gfx_status()
    )?;

    let precomputed_icon = match mode {
        GfxMode::Hybrid => None,
        GfxMode::Integrated => Some("󰰃"),
        GfxMode::NvidiaNoModeset => Some("󰰒"),
        GfxMode::Vfio => Some("󰰪"),
        GfxMode::AsusEgpu => Some("󰯷"),
        GfxMode::AsusMuxDgpu => Some("󰰏"),
        GfxMode::None => Some("󰳤"),
    };

    if let Some(i) = precomputed_icon {
        // It shouldn't be listening if it won't turn off and on
        info!("Supergfxd mode is {}, skipping listener", mode);
        Ok((None, None, i))
    } else {
        Ok((
            Some(proxy),
            Some(SuperGfxPowerStream::new(status_stream)),
            status.icon(),
        ))
    }
}

pub async fn get_icon<'a>(proxy: &xmlgen::DaemonProxy<'a>) -> Icon<'a> {
    proxy.power().await.unwrap_or_default().icon()
}

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
impl GfxPower {
    pub fn icon<'a>(&self) -> Icon<'a> {
        match self {
            GfxPower::Active => "󰒇",
            GfxPower::Suspended => "󰒆",
            GfxPower::Off => "󰒅",
            GfxPower::AsusDisabled => "󰒈",
            GfxPower::AsusMuxDiscreet => "󰾂",
            GfxPower::Unknown => "󰾂 ?",
        }
    }
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

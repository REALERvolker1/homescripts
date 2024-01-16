use super::*;
// use crate::types::*;
use futures::StreamExt;
use tracing::{debug, error, warn};
use zbus::zvariant::OwnedValue;
mod xmlgen;
use serde::{Deserialize, Serialize};

pub struct PowerProfilesModule<'a> {
    state: PowerProfileState,
    proxy: xmlgen::PowerProfilesProxy<'a>,
    stream: zbus::PropertyStream<'a, PowerProfileState>,
}
impl<'a> StaticModule for PowerProfilesModule<'a> {
    #[inline]
    fn name(&self) -> &str {
        "Power Profiles Daemon"
    }
    #[inline]
    fn mod_type(&self) -> ModuleType {
        ModuleType::Dbus
    }
    #[tracing::instrument(skip(self, ipc))]
    async fn update_server(&self, ipc: &IpcCh) -> ModResult<()> {
        // let mut guard = ipc.lock();
        ipc.send(StateType::PowerProfiles(self.state)).await?;
        Ok(())
    }
}
impl<'a> DbusModule<'a> for PowerProfilesModule<'a> {
    #[tracing::instrument(skip(connection))]
    async fn new(connection: &zbus::Connection) -> ModResult<Self> {
        let proxy = xmlgen::PowerProfilesProxy::new(connection).await?;
        let (state, stream) = tokio::join!(
            proxy.active_profile(),
            proxy.receive_active_profile_changed()
        );
        Ok(Self {
            state: state?,
            proxy,
            stream,
        })
    }
}
impl<'a> Module for PowerProfilesModule<'a> {
    #[tracing::instrument(skip(self))]
    async fn update(&mut self, payload: RecvType) -> ModResult<()> {
        if let RecvType::PowerProfile(s) = payload {
            self.state = s;
            Ok(())
        } else {
            let out = format!(
                "Power Profiles module received an invalid payload: {:?}",
                payload
            );
            error!("{out}");
            Err(ModError::UpdateError(out))
        }
    }
    #[tracing::instrument(skip(self, ipc))]
    async fn run(&mut self, ipc: IpcCh) -> ModResult<()> {
        self.update_server(&ipc).await?;
        while let Some(s) = self.stream.next().await {
            if let Ok(p) = s.get().await {
                if self.update(RecvType::PowerProfile(p)).await.is_ok() {
                    self.update_server(&ipc).await?;
                }
            }
        }
        Ok(())
    }
    #[inline]
    fn should_run(&self) -> bool {
        true
    }
}

#[derive(Debug, Default, strum_macros::Display, Copy, Clone, Serialize, Deserialize)]
#[strum(serialize_all = "kebab-case")]
pub enum PowerProfileState {
    PowerSaver,
    Balanced,
    Performance,
    #[default]
    Unknown,
}
impl From<&str> for PowerProfileState {
    fn from(value: &str) -> Self {
        match value {
            "power-saver" => Self::PowerSaver,
            "balanced" => Self::Balanced,
            "performance" => Self::Performance,
            _ => {
                warn!("Could not match '{}' to a known power profile state", value);
                Self::Unknown
            }
        }
    }
}
impl TryFrom<OwnedValue> for PowerProfileState {
    type Error = ModError;
    fn try_from(value: OwnedValue) -> Result<Self, Self::Error> {
        debug!(
            "Trying to convert from OwnedValue '{:?}' to PowerProfileState",
            value
        );
        Ok(if let Some(v) = value.downcast_ref() {
            Self::from(v)
        } else {
            warn!(
                "Could not match '{:?}' to a known power profile state",
                value
            );
            Self::default()
        })
    }
}
impl PowerProfileState {
    pub fn icon(&self) -> Option<Icon> {
        match self {
            Self::PowerSaver => Some('󰌪'),
            Self::Balanced => Some('󰛲'),
            Self::Performance => Some('󱐋'),
            _ => None,
        }
    }
}
impl FmtModule for PowerProfileState {
    fn stdout(&self) -> String {
        if let Some(i) = self.icon() {
            i.to_string()
        } else {
            String::new()
        }
    }
    fn waybar(&self) -> String {
        let myself = self.to_string();
        let text = if let Some(i) = self.icon() {
            i.to_string()
        } else {
            String::new()
        };
        waybar_fmt(&text, &text, &myself, &myself, None)
    }
}

/// Preferences for the Power-profiles-daemon module
#[derive(Debug, SmartDefault, Serialize, Deserialize)]
pub struct PowerProfilesConfig {
    /// Enable the module
    #[default(AutoBool::default())]
    enable: AutoBool,
}

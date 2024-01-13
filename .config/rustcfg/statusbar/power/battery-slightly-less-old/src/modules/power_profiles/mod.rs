use crate::{
    experimental::*,
    modules::{Icon, ListenerType, ProxyType, StateType},
    types::ModError,
};
use tracing::{debug, warn};
use zbus::zvariant::OwnedValue;
pub mod xmlgen;

pub struct PowerProfilesModule<'a> {
    state: PowerProfileState,
    proxy: xmlgen::PowerProfilesProxy<'a>,
    stream: zbus::PropertyStream<'a, PowerProfileState>,
}
impl<'a> Module for PowerProfilesModule<'a> {
    #[tracing::instrument(skip(connection))]
    async fn init(connection: &zbus::Connection) -> Result<Option<Self>, ModError> {
        let proxy = xmlgen::PowerProfilesProxy::new(connection).await?;
        let (state, stream) = tokio::join!(
            proxy.active_profile(),
            proxy.receive_active_profile_changed()
        );
        Ok(Some(Self {
            state: state?,
            proxy,
            stream,
        }))
    }
    fn name(&self) -> &str {
        "Power Profiles Daemon"
    }
    async fn update(&mut self, payload: RecvType) -> Result<(), ModError> {
        if let RecvType::PowerProfile(s) = payload {
            self.state = s;
            Ok(())
        } else {
            Err(ModError::UpdateError(format!(
                "Power Profiles module received an invalid payload: {:?}",
                payload
            )))
        }
    }
}

#[tracing::instrument(skip(connection))]
pub async fn create_power_profiles_module<'a>(
    connection: &zbus::Connection,
) -> zbus::Result<(ProxyType<'a>, StateType, ListenerType<'a>)> {
    debug!("Trying to create power-profiles-daemon module");
    let proxy = xmlgen::PowerProfilesProxy::new(connection).await?;
    let (state, state_stream) = tokio::join!(
        proxy.active_profile(),
        proxy.receive_active_profile_changed()
    );
    Ok((
        ProxyType::PowerProfile(proxy),
        StateType::PowerProfile(state?),
        ListenerType::PowerProfile(state_stream),
    ))
}

#[derive(Debug, Default, strum_macros::Display, PartialEq, Eq, Copy, Clone)]
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
    pub fn icon<'a>(&self) -> Icon<'a> {
        match self {
            Self::PowerSaver => "󰌪",
            Self::Balanced => "󰛲",
            Self::Performance => "󱐋",
            _ => "󱐋?",
        }
    }
}

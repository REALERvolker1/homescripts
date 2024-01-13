use crate::{
    modules::{Icon, ListenerType, ProxyType, StateType},
    types::ModError,
};
use tracing::{debug, warn};
use zbus::zvariant::OwnedValue;
pub mod xmlgen;

type Res<'a> = zbus::Result<(ProxyType<'a>, StateType, ListenerType<'a>)>;

#[tracing::instrument(skip(connection))]
pub async fn create_power_profiles_module<'a>(connection: &zbus::Connection) -> Res<'a> {
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

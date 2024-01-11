use crate::{
    modules::{Icon, ListenerType, ProxyType, StateType},
    types::ModError,
};
use serde::{Deserialize, Serialize};
use tracing::{debug, info, warn};
use zbus::zvariant::{OwnedValue, Type};
pub mod xmlgen;


type Res<'a> = zbus::Result<(
    ProxyType<'a>,
    StateType,
    StateType,
    StateType,
    ListenerType<'a>,
    ListenerType<'a>,
    ListenerType<'a>,
)>;
#[tracing::instrument(skip(connection))]
pub async fn create_upower_module<'a>(connection: &zbus::Connection) -> Res<'a> {
    debug!("Trying to create upower module");
    let proxy = xmlgen::DeviceProxy::new(connection).await?;
    let (s, p, r, state_stream, percent_stream, rate_stream) = tokio::join!(
        proxy.state(),
        proxy.percentage(),
        proxy.energy_rate(),
        proxy.receive_state_changed(),
        proxy.receive_percentage_changed(),
        proxy.receive_energy_rate_changed()
    );
    info!("Created UPower module");
    Ok((
        ProxyType::Upower(proxy),
        StateType::BatteryState(s?),
        StateType::BatteryPercentage(p?),
        StateType::BatteryRate(r?),
        ListenerType::BatteryState(state_stream),
        ListenerType::BatteryPercentage(percent_stream),
        ListenerType::BatteryRate(rate_stream),
    ))
}

/// The current state of the battery, an enum based on its representation in upower
#[derive(Debug, Copy, Clone, PartialEq, Eq, Default, strum_macros::Display)]
pub enum BatteryState {
    Charging,
    Discharging,
    Empty,
    FullyCharged,
    PendingCharge,
    PendingDischarge,
    #[default]
    Unknown,
}
impl From<u32> for BatteryState {
    fn from(value: u32) -> Self {
        debug!("Converting from u32 '{}'", value);
        match value {
            1 => Self::Charging,
            2 => Self::Discharging,
            3 => Self::Empty,
            4 => Self::FullyCharged,
            5 => Self::PendingCharge,
            6 => Self::PendingDischarge,
            _ => {
                warn!("Could not match u32 '{}' to a known BatteryState", value);
                Self::default()
            }
        }
    }
}
impl TryFrom<OwnedValue> for BatteryState {
    type Error = ModError;
    fn try_from(value: OwnedValue) -> Result<Self, Self::Error> {
        debug!("Trying to convert OwnedValue '{:?}' to a known type", value);
        Ok(if let Some(v) = value.downcast_ref::<u32>() {
            Self::from(*v)
        } else {
            Self::default()
        })
    }
}

// pub type Percent = u8;
#[derive(
    Debug, Default, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Type, Serialize, Deserialize,
)]
pub struct Percent {
    v: u8,
}
impl Percent {
    /// Get the inner value
    pub fn u(&self) -> u8 {
        self.v
    }
    /// Get the max value
    pub fn max() -> Self {
        Self { v: 100 }
    }
    /// Create a new Percentage, without checking if the value is in range. Useful for hardcoded values.
    pub fn from_u8_unchecked(u: u8) -> Self {
        warn!(
            "Converting u8 '{}' to Percentage type without checking bounds",
            u
        );
        Self { v: u }
    }
    /// Try to convert a str into a percentage.
    /// I literally only made this method for argparsing, but it should just work in other places.
    pub fn try_from_str<S>(value: S) -> Result<Self, ModError>
    where
        S: AsRef<str>,
    {
        let v = value.as_ref();
        debug!("Trying to convert from AsRef<str> '{:?}'", v);
        if let Ok(v) = v.trim().parse::<u8>() {
            Self::try_from(v)
        } else {
            Err(ModError::Conversion(format!(
                "Failed to parse percentage from string! {}",
                v
            )))
        }
    }
}
impl std::fmt::Display for Percent {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}%", self.v)
    }
}
impl TryFrom<u8> for Percent {
    type Error = ModError;
    fn try_from(value: u8) -> Result<Self, Self::Error> {
        debug!("Trying to convert u8 '{}' to Percentage", value);
        if value > 100 {
            Err(ModError::Conversion(format!("Value too high! {}", value)))
        } else {
            Ok(Self { v: value })
        }
    }
}
impl TryFrom<f64> for Percent {
    type Error = ModError;
    fn try_from(value: f64) -> Result<Self, Self::Error> {
        debug!("Trying to convert f64 '{}' to Percentage", value);
        let uval = value as u8;
        Self::try_from(uval)
    }
}
impl TryFrom<OwnedValue> for Percent {
    type Error = ModError;
    fn try_from(value: OwnedValue) -> Result<Self, Self::Error> {
        debug!("Trying to convert from OwnedValue '{:?}' to Percent", value);
        if let Some(v) = value.downcast_ref::<f64>() {
            Self::try_from(v.floor())
        } else if let Some(v) = value.downcast_ref::<u8>() {
            Self::try_from(*v)
        } else {
            Err(ModError::Conversion(format!(
                "Failed to parse percentage from value! {:?}",
                value
            )))
        }
    }
}

pub fn battery_icon<'a>(percent: Percent, state: BatteryState) -> Icon<'a> {
    match state {
        BatteryState::Charging => match percent.u() {
            101.. => "󰂏?",
            95.. => "󰂅",
            91.. => "󰂋",
            81.. => "󰂊",
            71.. => "󰢞",
            61.. => "󰂉",
            51.. => "󰢝",
            41.. => "󰂈",
            31.. => "󰂇",
            21.. => "󰂆",
            11.. => "󰢜",
            _ => "󰢟",
        },
        BatteryState::Discharging => match percent.u() {
            101.. => "󰂌?",
            95.. => "󰁹",
            91.. => "󰂂",
            81.. => "󰂁",
            71.. => "󰂀",
            61.. => "󰁿",
            51.. => "󰁾",
            41.. => "󰁽",
            31.. => "󰁼",
            21.. => "󰁻",
            11.. => "󰁺",
            _ => "󰂎",
        },
        BatteryState::Empty => "󱟩",
        BatteryState::FullyCharged => "󰂄",
        BatteryState::PendingCharge => "󰂏",
        BatteryState::PendingDischarge => "󰂌",
        BatteryState::Unknown => "󱉞?",
    }
}

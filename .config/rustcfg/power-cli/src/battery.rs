use serde::{Deserialize, Serialize};
use std::{convert::TryFrom, fmt, str::FromStr};

#[derive(Debug, Copy, Clone, PartialEq, Default, Serialize, Deserialize)]
#[repr(u32)]
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

// #[derive(Debug, Default, Type, PartialEq, Eq, Copy, Clone)]
// #[repr(u32)]
// pub enum BatteryLevel {
//     Unknown = 0,
//     None = 1,
//     Low = 3,
//     Critical = 4,
//     Normal = 6,
//     High = 7,
//     Full = 8,
// }

impl TryFrom<u32> for BatteryState {
    type Error = ();
    fn try_from(value: u32) -> Result<Self, Self::Error> {
        match value {
            1 => Ok(BatteryState::Charging),
            2 => Ok(BatteryState::Discharging),
            3 => Ok(BatteryState::Empty),
            4 => Ok(BatteryState::FullyCharged),
            5 => Ok(BatteryState::PendingCharge),
            6 => Ok(BatteryState::PendingDischarge),
            _ => Ok(BatteryState::Unknown),
        }
    }
}

impl FromStr for BatteryState {
    type Err = fmt::Error;
    fn from_str(s: &str) -> Result<Self, fmt::Error> {
        match s.to_lowercase().trim() {
            "charging" => Ok(BatteryState::Charging),
            "discharging" => Ok(BatteryState::Discharging),
            "empty" => Ok(BatteryState::Empty),
            "fullycharged" => Ok(BatteryState::FullyCharged),
            "pendingcharge" => Ok(BatteryState::PendingCharge),
            "pendingdischarge" => Ok(BatteryState::PendingDischarge),
            _ => Ok(BatteryState::Unknown),
        }
    }
}
impl fmt::Display for BatteryState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Charging => write!(f, "{:?}", &self),
            Self::Discharging => write!(f, "{:?}", &self),
            Self::Empty => write!(f, "{:?}", &self),
            Self::FullyCharged => write!(f, "{:?}", &self),
            Self::PendingCharge => write!(f, "{:?}", &self),
            Self::PendingDischarge => write!(f, "{:?}", &self),
            Self::Unknown => write!(f, "{:?}", &self),
        }
    }
}

pub fn battery_icon(state: BatteryState, percentage: u8) -> &'static str {
    match state {
        BatteryState::Charging => match percentage {
            101.. => "󰂏?",
            91.. => "󰂋",
            81.. => "󰂊",
            71.. => "󰢞",
            61.. => "󰂉",
            51.. => "󰢝",
            41.. => "󰂈",
            31.. => "󰂇",
            21.. => "󰂆",
            11.. => "󰢜",
            0.. => "󰢟",
        },
        BatteryState::Discharging => match percentage {
            101.. => "󰂌?",
            91.. => "󰂂",
            81.. => "󰂁",
            71.. => "󰂀",
            61.. => "󰁿",
            51.. => "󰁾",
            41.. => "󰁽",
            31.. => "󰁼",
            21.. => "󰁻",
            11.. => "󰁺",
            0.. => "󰂎",
        },
        BatteryState::Empty => "󱟩",
        BatteryState::FullyCharged => "󰂄",
        BatteryState::PendingCharge => "󰂏",
        BatteryState::PendingDischarge => "󰂌",
        BatteryState::Unknown => "󰂑?",
    }
}

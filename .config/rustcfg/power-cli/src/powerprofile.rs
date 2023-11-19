use std::{convert::TryFrom, fmt, str::FromStr};
use serde::{Deserialize, Serialize};
use zbus::zvariant::Type;

// #[derive(Debug, Copy, Clone)]
#[derive(Debug, Default, Type, PartialEq, Eq, Copy, Clone, Serialize, Deserialize)]
pub enum PowerProfile {
    PowerSaver,
    Balanced,
    Performance,
    #[default]
    Unknown,
}
impl FromStr for PowerProfile {
    type Err = fmt::Error;
    fn from_str(s: &str) -> Result<Self, fmt::Error> {
        match s.to_lowercase().trim() {
            "power-saver" => Ok(PowerProfile::PowerSaver),
            "balanced" => Ok(PowerProfile::Balanced),
            "performance" => Ok(PowerProfile::Performance),
            _ => Ok(PowerProfile::Unknown),
        }
    }
}

impl TryFrom<&str> for PowerProfile {
    type Error = ();
    fn try_from(s: &str) -> Result<Self, Self::Error> {
        match s.to_lowercase().trim() {
            "power-saver" => Ok(PowerProfile::PowerSaver),
            "balanced" => Ok(PowerProfile::Balanced),
            "performance" => Ok(PowerProfile::Performance),
            _ => Ok(PowerProfile::Unknown),
        }
    }
}

impl fmt::Display for PowerProfile {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::PowerSaver => write!(f, "{:?}", &self),
            Self::Balanced => write!(f, "{:?}", &self),
            Self::Performance => write!(f, "{:?}", &self),
            Self::Unknown => write!(f, "{:?}", &self),
        }
    }
}

pub fn powerprofile_icon(profile: PowerProfile) -> &'static str {
    match profile {
        PowerProfile::PowerSaver => "󰌪",
        PowerProfile::Balanced => "󰛲",
        PowerProfile::Performance => "󱐋",
        PowerProfile::Unknown => "󱐋?",
    }
}

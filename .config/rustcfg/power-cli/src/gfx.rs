use serde::{Deserialize, Serialize};
use std::{fmt, str::FromStr};
use zbus::zvariant::Type;
// https://gitlab.com/asus-linux/supergfxctl/-/blob/main/src/pci_device.rs?ref_type=heads

#[derive(Debug, Default, Type, PartialEq, Eq, Copy, Clone, Serialize, Deserialize)]
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
impl FromStr for GfxMode {
    type Err = fmt::Error;
    fn from_str(s: &str) -> Result<Self, fmt::Error> {
        match s.to_lowercase().trim() {
            "hybrid" => Ok(GfxMode::Hybrid),
            "integrated" => Ok(GfxMode::Integrated),
            "nvidianomodeset" => Ok(GfxMode::NvidiaNoModeset),
            "vfio" => Ok(GfxMode::Vfio),
            "asusegpu" => Ok(GfxMode::AsusEgpu),
            "asusmuxdgpu" => Ok(GfxMode::AsusMuxDgpu),
            _ => Ok(GfxMode::None),
        }
    }
}

impl fmt::Display for GfxMode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Hybrid => write!(f, "{:?}", &self),
            Self::Integrated => write!(f, "{:?}", &self),
            Self::NvidiaNoModeset => write!(f, "{:?}", &self),
            Self::Vfio => write!(f, "{:?}", &self),
            Self::AsusEgpu => write!(f, "{:?}", &self),
            Self::AsusMuxDgpu => write!(f, "{:?}", &self),
            Self::None => write!(f, "Unknown"),
        }
    }
}

#[derive(Debug, Default, Type, PartialEq, Eq, Copy, Clone, Serialize, Deserialize)]
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
    type Err = fmt::Error;

    fn from_str(s: &str) -> Result<Self, fmt::Error> {
        match s.to_lowercase().trim() {
            "active" => Ok(GfxPower::Active),
            "suspended" => Ok(GfxPower::Suspended),
            "off" => Ok(GfxPower::Off),
            _ => Ok(GfxPower::Unknown),
        }
    }
}

impl From<&GfxPower> for &str {
    fn from(gfx: &GfxPower) -> &'static str {
        match gfx {
            GfxPower::Active => "active",
            GfxPower::Suspended => "suspended",
            GfxPower::Off => "off",
            GfxPower::AsusDisabled => "dgpu_disabled",
            GfxPower::AsusMuxDiscreet => "asus_mux_discreet",
            GfxPower::Unknown => "unknown",
        }
    }
}
impl fmt::Display for GfxPower {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Active => write!(f, "{:?}", &self),
            Self::Suspended => write!(f, "{:?}", &self),
            Self::Off => write!(f, "{:?}", &self),
            Self::AsusDisabled => write!(f, "{:?}", &self),
            Self::AsusMuxDiscreet => write!(f, "{:?}", &self),
            Self::Unknown => write!(f, "{:?}", &self),
        }
    }
}

// pub fn gfxmode_icon(mode: GfxMode) -> &'static str {
//     match mode {
//         GfxMode::Hybrid => "󰰀",
//         GfxMode::Integrated => "󰰃",
//         GfxMode::NvidiaNoModeset => "󰰒",
//         GfxMode::Vfio => "󰰪",
//         GfxMode::AsusEgpu => "󰯷",
//         GfxMode::AsusMuxDgpu => "󰰏",
//         GfxMode::None => "󰳤",
//     }
// }

// pub fn gfxpower_icon(power: GfxPower) -> &'static str {
//     match power {
//         GfxPower::Active => "󰒇",
//         GfxPower::Suspended => "󰒆",
//         GfxPower::Off => "󰒅",
//         GfxPower::AsusDisabled => "󰒈",
//         GfxPower::AsusMuxDiscreet => "󰾂",
//         GfxPower::Unknown => "󰾂?",
//     }
// }

pub fn gfx_icon(mode: GfxMode, power: GfxPower) -> &'static str {
    match mode {
        GfxMode::Hybrid => match power {
            GfxPower::Active => "󰒇",
            GfxPower::Suspended => "󰒆",
            GfxPower::Off => "󰒅",
            GfxPower::AsusDisabled => "󰒈",
            GfxPower::AsusMuxDiscreet | GfxPower::Unknown => "󰾂",
        },
        GfxMode::Integrated => "󰰃",
        GfxMode::NvidiaNoModeset => "󰰒",
        GfxMode::Vfio => "󰰪",
        GfxMode::AsusEgpu => "󰯷",
        GfxMode::AsusMuxDgpu => "󰰏",
        GfxMode::None => "󰳤",
    }
}

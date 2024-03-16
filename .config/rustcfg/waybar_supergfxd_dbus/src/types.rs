use serde::{Deserialize, Serialize};
use zbus::zvariant;
// type Icon = &'static str;
type Icon = char;

#[derive(Debug, Default, PartialEq, Eq, Copy, Clone, zvariant::Type, Serialize, Deserialize)]
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
    pub const fn icon(&self) -> Option<Icon> {
        match self {
            GfxMode::Hybrid => None,
            GfxMode::Integrated => Some('󰰃'),
            GfxMode::NvidiaNoModeset => Some('󰰒'),
            GfxMode::Vfio => Some('󰰪'),
            GfxMode::AsusEgpu => Some('󰯷'),
            GfxMode::AsusMuxDgpu => Some('󰰏'),
            GfxMode::None => Some('󰳤'),
        }
    }
}

#[derive(Debug, Default, PartialEq, Eq, Copy, Clone, zvariant::Type, Serialize, Deserialize)]
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
    pub const fn icon(&self) -> Icon {
        match self {
            GfxPower::Active => '󰒇',
            GfxPower::Suspended => '󰒆',
            GfxPower::Off => '󰒅',
            GfxPower::AsusDisabled => '󰒈',
            GfxPower::AsusMuxDiscreet => '󰾂',
            GfxPower::Unknown => '󰳤',
        }
    }
    pub const fn class_name(&self) -> &'static str {
        match self {
            GfxPower::Active => "active",
            GfxPower::Suspended => "suspended",
            GfxPower::Off => "off",
            GfxPower::AsusDisabled => "asus-disabled",
            GfxPower::AsusMuxDiscreet => "asus-mux-discreet",
            GfxPower::Unknown => "unknown",
        }
    }
}

// static POWER_MAP: phf::Map<&'static str, GfxPower> = phf_macros::phf_map! {
//     "active" => GfxPower::Active,
//     "suspended" => GfxPower::Suspended,
//     "off" => GfxPower::Off,
//     "asus-disabled" => GfxPower::AsusDisabled,
//     "asus-mux-discreet" => GfxPower::AsusMuxDiscreet,
// };

use serde::{Deserialize, Serialize};
use zbus::zvariant;
type Icon = &'static str;

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
            GfxMode::Integrated => Some("󰰃"),
            GfxMode::NvidiaNoModeset => Some("󰰒"),
            GfxMode::Vfio => Some("󰰪"),
            GfxMode::AsusEgpu => Some("󰯷"),
            GfxMode::AsusMuxDgpu => Some("󰰏"),
            GfxMode::None => Some("󰳤"),
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
            GfxPower::Active => "󰒇\n",
            GfxPower::Suspended => "󰒆\n",
            GfxPower::Off => "󰒅\n",
            GfxPower::AsusDisabled => "󰒈\n",
            GfxPower::AsusMuxDiscreet => "󰾂\n",
            GfxPower::Unknown => "󰳤\n",
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

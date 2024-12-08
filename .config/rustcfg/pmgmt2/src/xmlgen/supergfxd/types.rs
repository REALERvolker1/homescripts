use serde::{Deserialize, Serialize};
use zbus::zvariant;

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
// impl GfxMode {
//     pub const fn icon(&self) -> Option<Icon> {
//         let icon = match self {
//             GfxMode::Hybrid => return None,
//             GfxMode::Integrated => '󰰃',
//             GfxMode::NvidiaNoModeset => '󰰒',
//             GfxMode::Vfio => '󰰪',
//             GfxMode::AsusEgpu => '󰯷',
//             GfxMode::AsusMuxDgpu => '󰰏',
//             GfxMode::None => '󰳤',
//         };

//         return Some(icon);
//     }
// }

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
    // pub const fn icon(&self) -> Icon {
    //     match self {
    //         GfxPower::Active => '󰒇',
    //         GfxPower::Suspended => '󰒆',
    //         GfxPower::Off => '󰒅',
    //         GfxPower::AsusDisabled => '󰒈',
    //         GfxPower::AsusMuxDiscreet => '󰾂',
    //         GfxPower::Unknown => '󰳤',
    //     }
    // }
    // pub const fn class_name(&self) -> &'static str {
    //     match self {
    //         GfxPower::Active => "active",
    //         GfxPower::Suspended => "suspended",
    //         GfxPower::Off => "off",
    //         GfxPower::AsusDisabled => "asus-disabled",
    //         GfxPower::AsusMuxDiscreet => "asus-mux-discreet",
    //         GfxPower::Unknown => "unknown",
    //     }
    // }
}

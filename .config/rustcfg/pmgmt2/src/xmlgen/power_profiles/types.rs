use {
    ::core::str::FromStr,
    ::serde::{Deserialize, Serialize},
};

macro_rules! str_from_ownedvalue_or_default {
    ($type:ident) => {
        impl From<zbus::zvariant::OwnedValue> for $type {
            fn from(value: zbus::zvariant::OwnedValue) -> Self {
                if let Ok(s) = value.downcast_ref() {
                    if let Ok(me) = Self::from_str(s) {
                        return me;
                    }
                }

                Self::default()
            }
        }
    };
}

#[derive(
    Debug,
    Default,
    strum_macros::Display,
    strum_macros::EnumString,
    Copy,
    Clone,
    Serialize,
    Deserialize,
)]
#[strum(serialize_all = "kebab-case")]
#[serde(rename_all = "kebab-case")]
pub enum PowerProfileState {
    PowerSaver,
    Balanced,
    Performance,
    #[default]
    Unknown,
}
str_from_ownedvalue_or_default!(PowerProfileState);

// #[derive(
//     Debug,
//     Default,
//     PartialEq,
//     Eq,
//     Copy,
//     Clone,
//     strum_macros::Display,
//     strum_macros::EnumString,
//     Deserialize_repr,
//     Serialize_repr,
// )]
// #[repr(u32)]
// #[strum(serialize_all = "kebab-case")]
// pub enum GfxMode {
//     Hybrid,
//     Integrated,
//     NvidiaNoModeset,
//     Vfio,
//     AsusEgpu,
//     AsusMuxDgpu,
//     #[default]
//     None,
// }
// str_from_ownedvalue_or_default!(GfxMode);

// #[derive(
//     Debug,
//     Default,
//     PartialEq,
//     Eq,
//     Copy,
//     Clone,
//     strum_macros::Display,
//     strum_macros::EnumString,
//     Deserialize_repr,
//     Serialize_repr,
// )]
// #[repr(u32)]
// #[strum(serialize_all = "kebab-case")]
// pub enum GfxPower {
//     Active,
//     Suspended,
//     Off,
//     AsusDisabled,
//     AsusMuxDiscreet,
//     #[default]
//     Unknown,
// }
// str_from_ownedvalue_or_default!(GfxPower);

use super::*;
use hyprland::{data::Mouse, keyword::OptionValue, shared::Address};

#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Serialize,
    Deserialize,
    strum_macros::Display,
    strum_macros::VariantArray,
    strum_macros::VariantNames,
)]
#[strum(serialize_all = "snake_case")]
pub enum Backends {
    Xorg,
    Hyprland,
}

#[derive(
    Debug, Default, Clone, Eq, Hash, PartialEq, derive_more::Display, Serialize, Deserialize,
)]
#[display(fmt = "{} ({})", name, id)]
pub struct Device {
    pub name: String,
    pub id: DeviceId,
}
impl Device {
    pub fn get_id_x11(&self) -> Res<usize> {
        if let DeviceId::X11Id(id) = self.id {
            Ok(id)
        } else {
            Err(anyhow!("Device {self:?} is not a X11 device"))
        }
    }
    pub fn get_address_hyprland<'a>(&'a self) -> Res<&'a Address> {
        let my_id = &self.id;
        if let Some(h) = my_id.get_hypr() {
            Ok(h)
        } else {
            Err(anyhow!("Device {self:?} is not a Hyprland device"))
        }
        // if let Some(id) = self.id {
        //     Ok(id)
        // } else {
        //     Err(anyhow!("Pointer {self:?} is not a hyprland mouse!"))
        // }
    }
    pub fn name_contains(&self, needle: &str) -> bool {
        self.name.contains(needle)
    }
    pub fn is_mouse(&self) -> bool {
        for i in CONFIG.mouse_identifiers.iter() {
            if self.name.contains(i) {
                return true;
            }
        }
        false
    }
    pub fn from_hyprland_mouse(value: Mouse) -> Self {
        Device {
            name: value.name,
            id: DeviceId::HyprAddress(value.address),
        }
    }
}

#[derive(
    Debug,
    Default,
    Clone,
    Eq,
    Hash,
    PartialEq,
    derive_more::Display,
    strum_macros::EnumTryAs,
    Serialize,
    Deserialize,
)]
pub enum DeviceId {
    #[display(fmt = "{_0}")]
    X11Id(usize),
    #[display(fmt = "{_0}")]
    HyprAddress(Address),
    #[default]
    #[display(fmt = "None")]
    None,
}
impl DeviceId {
    pub fn get_hypr<'a>(&'a self) -> Option<&'a Address> {
        match self {
            DeviceId::HyprAddress(h) => Some(h),
            _ => None,
        }
    }
}

pub type Icon = &'static str;

#[derive(
    Debug,
    Clone,
    Default,
    Copy,
    Eq,
    Hash,
    PartialEq,
    strum_macros::Display,
    strum_macros::EnumIter,
    Serialize,
    Deserialize,
)]
#[strum(serialize_all = "lowercase")]
pub enum Status {
    On,
    Off,
    #[default]
    Unknown,
}

impl Status {
    pub fn from_bool(b: bool) -> Self {
        if b {
            Self::On
        } else {
            Self::Off
        }
    }
    pub fn from_str(str: &str) -> Self {
        match str.trim().to_ascii_lowercase().as_str() {
            "on" | "true" | "1" => Self::On,
            "off" | "false" | "0" => Self::Off,
            _ => Self::Unknown,
        }
    }
    pub fn from_int<T>(int: T) -> Self
    where
        T: Into<u8>,
    {
        match int.into() {
            0 => Self::Off,
            1 => Self::On,
            _ => Self::Unknown,
        }
    }
    pub fn from_opt(o: &OptionValue) -> Self {
        match o {
            OptionValue::Float(f) => Self::from_int(*f as u8),
            OptionValue::Int(i) => Self::from_int(*i as u8),
            OptionValue::String(s) => Self::from_str(&s),
        }
    }
    pub fn toggle(&self) -> Self {
        match self {
            Self::On => Self::Off,
            Self::Off => Self::On,
            // when in doubt, don't get stranded without a working touchpad
            Self::Unknown => {
                eprintln!("Status toggle error: Unknown status, falling back to On");
                Self::On
            }
        }
    }
    pub fn toggle_bool(&self) -> bool {
        if self.toggle() == Self::On {
            true
        } else {
            false
        }
    }
    pub fn to_bool(&self) -> bool {
        match self {
            Self::On => true,
            Self::Off => false,
            Self::Unknown => {
                eprintln!("Status to bool error: Unknown status, falling back to true");
                true
            }
        }
    }
    pub fn to_bool_optionvalue(&self) -> OptionValue {
        if self.to_bool() {
            OptionValue::Int(1)
        } else {
            OptionValue::Int(0)
        }
    }
    pub const fn icon(&self) -> Icon {
        match self {
            Self::On => "󰟸",
            Self::Off => "󰤳",
            Self::Unknown => "󰟸 ?",
        }
    }
    /// intended to be used in config init
    pub fn update_iconfile_blocking(&self, file: &Path) -> tokio::io::Result<()> {
        std::fs::write(file, self.icon().as_bytes())
    }
    pub async fn update_iconfile(&self, file: &Path) -> tokio::io::Result<()> {
        tokio::fs::write(file, self.icon().as_bytes()).await
    }
}

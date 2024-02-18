use std::env;

use super::*;
use hyprland::keyword::OptionValue;

pub type Res<T> = simple_eyre::Result<T>;
pub type MouseList = HashSet<Mouse>;
pub type Conf = config::Config;

#[derive(
    Debug,
    Clone,
    Copy,
    clap::ValueEnum,
    PartialEq,
    Eq,
    Serialize,
    Deserialize,
    strum_macros::Display,
    strum_macros::VariantArray,
    strum_macros::VariantNames,
)]
#[clap(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum Backends {
    Xorg,
    Hyprland,
}
impl Default for Backends {
    fn default() -> Self {
        if env::var("HYPRLAND_INSTANCE_SIGNATURE").is_ok() {
            Self::Hyprland
        } else {
            Self::Xorg
        }
    }
}
impl Backends {
    #[inline]
    pub async fn new_backend_thing(&self, conf: Conf) -> Res<hypr::Hyprland> {
        hypr::Hyprland::new(conf).await
    }
}

#[derive(Debug, Clone, Eq, Hash, PartialEq, derive_more::Display, Serialize, Deserialize)]
#[display(fmt = "{} ({})", name, address)]
pub struct Mouse {
    pub name: String,
    pub address: hyprland::shared::Address,
}
impl From<hyprland::data::Mouse> for Mouse {
    fn from(value: hyprland::data::Mouse) -> Self {
        Self {
            name: value.name,
            address: value.address,
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
    pub fn from_bool(bool: bool) -> Self {
        if bool {
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

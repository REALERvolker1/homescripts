use crate::{cleanup, CONFIG};
use hyprland::{keyword::OptionValue, shared::HyprError};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::{env, fmt};
use tokio::{io, sync::mpsc::error::SendError};
use x11rb::rust_connection::{ConnectError, ConnectionError, ReplyError};

#[derive(Debug)]
pub enum PError {
    Hyprland(HyprError),
    XConnectionInit(ConnectError),
    XRuntime(ConnectionError),
    XReply(ReplyError),
    Io(io::Error),
    ArgParse(String),
    ConfigParse(String),
    Send(String),
    /// The lockfile from another instance is active
    Locked,
    /// No other instance available
    NotLocked,
    Other(String),
}
impl std::error::Error for PError {}
impl fmt::Display for PError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Hyprland(e) => e.fmt(f),
            Self::XConnectionInit(e) => e.fmt(f),
            Self::XRuntime(e) => e.fmt(f),
            Self::XReply(e) => e.fmt(f),
            Self::Io(e) => e.fmt(f),
            Self::ArgParse(e) => e.fmt(f),
            Self::ConfigParse(e) => e.fmt(f),
            Self::Send(e) => e.fmt(f),
            Self::Locked => "Locked Error: another instance seems to be running!".fmt(f),
            Self::NotLocked => "NotLocked Error: no other instance is running!".fmt(f),
            Self::Other(e) => e.fmt(f),
        }
    }
}
impl From<io::Error> for PError {
    fn from(e: io::Error) -> Self {
        Self::Io(e)
    }
}
impl From<HyprError> for PError {
    fn from(e: HyprError) -> Self {
        Self::Hyprland(e)
    }
}
impl From<&str> for PError {
    fn from(s: &str) -> Self {
        Self::Other(String::from(s))
    }
}
impl<T> From<SendError<T>> for PError
where
    T: std::fmt::Debug,
{
    fn from(e: SendError<T>) -> Self {
        Self::Send(format!("{:?}", e))
    }
}
impl From<ConnectError> for PError {
    fn from(e: ConnectError) -> Self {
        Self::XConnectionInit(e)
    }
}
impl From<ConnectionError> for PError {
    fn from(e: ConnectionError) -> Self {
        Self::XRuntime(e)
    }
}
impl From<ReplyError> for PError {
    fn from(e: ReplyError) -> Self {
        Self::XReply(e)
    }
}

pub type PResult<T> = Result<T, PError>;
pub type PNul = PResult<()>;

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
    strum_macros::VariantArray,
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
            Self::Unknown => Self::Unknown,
        }
    }
    pub fn to_bool(&self) -> Option<bool> {
        match self {
            Self::On => Some(true),
            Self::Off => Some(false),
            Self::Unknown => None,
        }
    }
    pub fn icon(&self) -> Icon {
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

#[derive(
    Debug,
    Clone,
    Copy,
    Eq,
    Hash,
    PartialEq,
    Default,
    Serialize,
    Deserialize,
    strum_macros::Display,
    strum_macros::EnumString,
    strum_macros::EnumMessage,
)]
#[strum(serialize_all = "lowercase")]
pub enum MatchType {
    #[strum(message = "Attempt to match using naive methods. Not recommended.")]
    Naive,
    #[strum(message = "Attempt to match by exact names")]
    Exact,
    #[default]
    #[strum(message = "Attempt to match by containing names. Recommended.")]
    Contains,
}
impl MatchType {
    /// filter mice, returning those that are named in the config.
    pub fn filter_mice(
        &self,
        devices: Vec<String>,
        mouse_names: &Vec<String>,
    ) -> Option<Vec<String>> {
        let mice = devices.into_iter();
        let matches: Vec<String> = match self {
            Self::Contains => mice
                .filter(|m| self.filter_contains(&m, mouse_names))
                .collect(),
            Self::Exact => mice
                .filter(|m| self.filter_equals(&m, mouse_names))
                .collect(),
            Self::Naive => mouse_names.to_owned(),
        };

        if matches.is_empty() {
            return Some(matches);
        }
        None
    }
    fn filter_contains(&self, mouse_name: &str, mouse_names: &Vec<String>) -> bool {
        for m in mouse_names.iter() {
            if mouse_name.contains(m) {
                return true;
            }
        }
        return false;
    }
    fn filter_equals(&self, mouse_name: &str, mouse_names: &Vec<String>) -> bool {
        for m in mouse_names.iter() {
            if mouse_name == m {
                return true;
            }
        }
        return false;
    }
}

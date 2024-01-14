use crate::*;
use serde::{Deserialize, Serialize};
use std::convert::Infallible;
use strum::EnumMessage;
use tracing::{debug, warn};
use zbus::zvariant::{OwnedValue, Type};

/// A sort of catch-all for errors
#[derive(Debug, Default, strum_macros::EnumMessage, strum_macros::EnumDiscriminants)]
pub enum ModError {
    #[strum(message = "Zbus Error")]
    Zbus(zbus::Error),
    #[strum(message = "Tokio io Error")]
    Io(tokio::io::Error),
    #[strum(message = "Failed to update state")]
    UpdateError(String),
    #[strum(message = "Conversion error")]
    Conversion(String),
    #[strum(message = "Nix system ERRNO")]
    Errno(nix::errno::Errno),
    #[strum(message = "Infallible error (Not so infallible after all!)")]
    Infallible(Infallible),
    #[strum(message = "Other error")]
    Other(String),
    #[strum(message = "Unknown error")]
    #[default]
    Unknown,
}
impl std::error::Error for ModError {}
impl std::fmt::Display for ModError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let message = self.get_message().unwrap_or("Error");
        // match self {
        //     Self::Zbus(e) => write!(f, "{}: {}", message, e),
        //     Self::Io(e) => write!(f, "{}: {}", message, e),
        //     Self::Errno(e) => write!(f, "{}: {}", message, e),
        //     Self::Infallible(e) => write!(f, "{}: {}", message, e),
        //     // Self::UpdateError(e) => write!(f, "{}: {}", message, e),
        //     // Self::Conversion(e) => write!(f, "{}: {}", message, e),
        //     // Self::ClassUpdateError(e) => write!(f, "{}: {}", message, e),
        //     Self::Other(e) => write!(f, "{}: {}", message, e),
        //     _ => write!(f, "{}: {:?}", message, self),
        // }
        write!(f, "{message}: {:?}", self)
    }
}
impl From<zbus::Error> for ModError {
    fn from(e: zbus::Error) -> Self {
        Self::Zbus(e)
    }
}
impl From<tokio::io::Error> for ModError {
    fn from(e: tokio::io::Error) -> Self {
        Self::Io(e)
    }
}
impl From<Infallible> for ModError {
    fn from(value: Infallible) -> Self {
        Self::Infallible(value)
    }
}
impl From<nix::errno::Errno> for ModError {
    fn from(value: nix::errno::Errno) -> Self {
        Self::Errno(value)
    }
}
impl Into<zbus::Error> for ModError {
    fn into(self) -> zbus::Error {
        match self {
            Self::Zbus(e) => e,
            _ => zbus::Error::Failure(self.to_string()),
        }
    }
}

/// The main type for icons
pub type Icon = char;

/// A boolean, but allows for the Auto value instead of just true or false.
///
/// useful for configuration
#[derive(
    Debug, Default, Clone, Copy, PartialEq, Eq, strum_macros::Display, Serialize, Deserialize,
)]
pub enum AutoBool {
    True,
    False,
    #[default]
    Auto,
}
impl From<bool> for AutoBool {
    fn from(b: bool) -> Self {
        if b {
            Self::True
        } else {
            Self::False
        }
    }
}

/// A percentage, a checked u8 between 0 and 100
#[derive(
    Debug, Default, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Type, Serialize, Deserialize,
)]
pub struct Percent {
    v: u8,
}
impl Percent {
    /// Get the inner value
    pub fn u(&self) -> u8 {
        self.v
    }
    /// Get the max value
    pub fn max() -> Self {
        Self { v: 100 }
    }
    /// Create a new Percentage, without checking if the value is in range. Useful for hardcoded values.
    pub fn from_u8_unchecked(u: u8) -> Self {
        warn!(
            "Converting u8 '{}' to Percentage type without checking bounds",
            u
        );
        Self { v: u }
    }
    /// Try to convert a str into a percentage.
    /// I literally only made this method for argparsing, but it should just work in other places.
    pub fn try_from_str<S>(value: S) -> Result<Self, ModError>
    where
        S: AsRef<str>,
    {
        let v = value.as_ref();
        debug!("Trying to convert from AsRef<str> '{:?}'", v);
        if let Ok(v) = v.trim().parse::<u8>() {
            Self::try_from(v)
        } else {
            Err(ModError::Conversion(format!(
                "Failed to parse percentage from string! {}",
                v
            )))
        }
    }
}
impl std::fmt::Display for Percent {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}%", self.v)
    }
}
impl TryFrom<u8> for Percent {
    type Error = ModError;
    fn try_from(value: u8) -> Result<Self, Self::Error> {
        debug!("Trying to convert u8 '{}' to Percentage", value);
        if value > 100 {
            Err(ModError::Conversion(format!("Value too high! {}", value)))
        } else {
            Ok(Self { v: value })
        }
    }
}
impl TryFrom<f64> for Percent {
    type Error = ModError;
    fn try_from(value: f64) -> Result<Self, Self::Error> {
        debug!("Trying to convert f64 '{}' to Percentage", value);
        let uval = value as u8;
        Self::try_from(uval)
    }
}
impl TryFrom<OwnedValue> for Percent {
    type Error = ModError;
    fn try_from(value: OwnedValue) -> Result<Self, Self::Error> {
        debug!("Trying to convert from OwnedValue '{:?}' to Percent", value);
        if let Some(v) = value.downcast_ref::<f64>() {
            Self::try_from(v.floor())
        } else if let Some(v) = value.downcast_ref::<u8>() {
            Self::try_from(*v)
        } else {
            Err(ModError::Conversion(format!(
                "Failed to parse percentage from value! {:?}",
                value
            )))
        }
    }
}

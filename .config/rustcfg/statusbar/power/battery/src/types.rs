use strum::EnumMessage;

use crate::modules::*;

/// A sort of catch-all for errors
#[derive(Debug, Default, strum_macros::EnumMessage, strum_macros::EnumDiscriminants)]
pub enum ModError {
    #[strum(message = "Zbus Error")]
    Zbus(zbus::Error),
    #[strum(message = "Tokio io Error")]
    Io(tokio::io::Error),
    #[strum(message = "Failed to bind property to global state")]
    StateAssignmentError(StateType),
    #[strum(message = "Failed to update class")]
    ClassUpdateError(store::ClassUpdateErrorType),
    #[strum(message = "Conversion error")]
    Conversion(String),
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
        match self {
            Self::Zbus(e) => write!(f, "{}: {}", message, e),
            Self::Io(e) => write!(f, "{}: {}", message, e),
            Self::Conversion(e) => write!(f, "{}: {}", message, e),
            Self::StateAssignmentError(e) => write!(f, "{}: {}", message, e),
            Self::ClassUpdateError(e) => write!(f, "{}: {}", message, e),
            Self::Other(e) => write!(f, "{}: {}", message, e),
            _ => write!(f, "{}: {:?}", message, self),
        }
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
impl Into<zbus::Error> for ModError {
    fn into(self) -> zbus::Error {
        match self {
            Self::Zbus(e) => e,
            _ => zbus::Error::Failure(self.to_string()),
        }
    }
}

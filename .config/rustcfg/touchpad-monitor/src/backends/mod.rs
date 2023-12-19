pub mod hyprland;
pub mod sway;
pub mod x11;

use std::{env::var, error::Error, fmt::Display};

/// Errors that can happen when detecting or using the backend
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BackendError {
    WaylandGeneric,
    Undetectable,
    Invalid,
    Unknown,
}

impl Error for BackendError {}
impl Display for BackendError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let msg = match self {
            BackendError::WaylandGeneric => "Failed to detect Wayland backend",
            BackendError::Undetectable => "Failed to detect any backend",
            BackendError::Invalid => "Invalid backend",
            _ => "Unknown and unreachable backend error",
        };
        write!(f, "{}, {}", self, msg)
    }
}

/// All the different backends supported by this crate
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Backend {
    Hyprland,
    Sway,
    X11,
    Auto,
    Invalid,
}
impl From<&str> for Backend {
    fn from(s: &str) -> Self {
        match s {
            "hyprland" => Backend::Hyprland,
            "sway" => Backend::Sway,
            "x11" => Backend::X11,
            "auto" => Backend::Auto,
            _ => Backend::Invalid,
        }
    }
}
impl Backend {
    /// A wrapper to make sure the backend is set and valid.
    pub fn ensure(backend: Backend) -> Result<Self, BackendError> {
        if backend == Backend::Invalid {
            // if it was undefined, the user input a wrong argument
            return Err(BackendError::Invalid);
        } else if backend == Backend::Auto {
            if let Ok(_wldisp) = var("WAYLAND_DISPLAY") {
                if let Ok(_h) = var("HYPRLAND_INSTANCE_SIGNATURE") {
                    Ok(Self::Hyprland)
                } else if let Ok(_s) = var("SWAYSOCK") {
                    Ok(Self::Sway)
                } else {
                    Err(BackendError::WaylandGeneric)
                }
            } else if let Ok(_disp) = var("DISPLAY") {
                Ok(Self::X11)
            } else {
                Err(BackendError::Undetectable)
            }
        } else {
            Ok(backend)
        }
    }
}

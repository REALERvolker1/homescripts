use super::*;

#[derive(Debug, thiserror::Error)]

pub enum StrErr {
    // #[error("IO error: {0}")]
    // Io(#[from] tokio::io::Error),
    // #[error("{0}")]
    // HyprError(#[from] hyprland::shared::HyprError),
    // #[error("Failed to connect to X11: {0}")]
    // XConnect(#[from] x11rb_async::errors::ConnectError),
    // #[error("X11 connection failed: {0}")]
    // XConnection(#[from] x11rb_async::errors::ConnectionError),
    #[error("{0}")]
    Static(&'static str),
    #[error("{0}")]
    Fmt(String),
    #[error("Unknown error")]
    Unknown,
}
impl From<&'static str> for StrErr {
    fn from(s: &'static str) -> Self {
        StrErr::Static(s)
    }
}
impl From<String> for StrErr {
    fn from(s: String) -> Self {
        StrErr::Fmt(s)
    }
}

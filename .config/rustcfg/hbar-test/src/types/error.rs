use crate::*;

pub type Bruh<T> = Result<T, BruhMoment>;
pub type NoBruh = Bruh<()>;

/// Errors that can be returned
#[derive(Debug, thiserror::Error)]
pub enum BruhMoment {
    #[error("Zbus error received: {0}")]
    Zbus(#[from] zbus::Error),
    #[error("IO error received: {0}")]
    Io(#[from] io::Error),
    #[error("\"Infallible\" error received: {0}")]
    Infallible(#[from] std::convert::Infallible),
    #[error("Integer conversion error: {0}")]
    FromInt(#[from] std::num::TryFromIntError),
    #[error("GTK Application exited with code: {0}")]
    GtkExit(i32),
    #[error("MPSC Send error received: {0}")]
    SendError(#[from] mpsc::error::SendError<modules::MpscData>),
    #[error("Conversion error: {0}")]
    Conversion(String),
    #[error("Unknown error occured")]
    Unknown,
}
impl From<glib::ExitCode> for BruhMoment {
    fn from(code: glib::ExitCode) -> Self {
        Self::GtkExit(code.value())
    }
}

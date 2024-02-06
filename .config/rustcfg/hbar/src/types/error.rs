use crate::*;

pub type ModResult<T> = Result<T, ModError>;

/// Errors that can be returned
#[derive(Debug, thiserror::Error)]
pub enum ModError {
    #[error("Zbus error received: {0}")]
    Zbus(#[from] zbus::Error),
    #[error("IO error received: {0}")]
    Io(#[from] io::Error),
    #[error("Environment variable error received: {0}")]
    Env(#[from] env::VarError),
    #[error("\"Infallible\" error received: {0}")]
    Infallible(#[from] std::convert::Infallible),
    #[error("Integer conversion error: {0}")]
    FromInt(#[from] std::num::TryFromIntError),
    #[error("Integer parse error: {0}")]
    ParseInt(#[from] std::num::ParseIntError),
    #[error("Float parse error: {0}")]
    ParseFloat(#[from] std::num::ParseFloatError),
    #[error("Failed to parse into enum: {0}")]
    StrumParseError(#[from] strum::ParseError),
    #[error("Failed to send data through pipe: {0}")]
    SendError(#[from] mpsc::error::SendError<modules::ModuleData>),
    #[error("Synchronously failed to send data through pipe: {0}")]
    SyncSendError(#[from] std::sync::mpsc::SendError<modules::ModuleData>),
    #[error("HTTP Request error: {0}")]
    Reqwest(#[from] reqwest::Error),
    #[error("Skipping module: {0}")]
    ModuleSkip(&'static str),
    #[error("File not found: {}", .0.display())]
    FileNotFound(PathBuf),
    #[error("Conversion error: {0}")]
    Conversion(String),
    #[error("Error: {0}")]
    Other(String),
    #[error("Unknown error occured")]
    Unknown,
}
impl From<()> for ModError {
    fn from(_: ()) -> Self {
        Self::Unknown
    }
}
impl From<&str> for ModError {
    fn from(value: &str) -> Self {
        Self::Other(value.to_owned())
    }
}
impl From<String> for ModError {
    fn from(value: String) -> Self {
        Self::Other(value)
    }
}
impl Into<zbus::Error> for ModError {
    fn into(self) -> zbus::Error {
        zbus::Error::Unsupported
    }
}

pub trait ErrorExt<T> {
    fn nullify(self) -> ();
    fn optify(self) -> Option<T>;
}
impl<T, E> ErrorExt<T> for std::result::Result<T, E>
where
    E: fmt::Display,
{
    fn nullify(self) -> () {
        match self {
            Ok(_) => (),
            Err(e) => {
                eprintln!("{e}");
            }
        }
    }
    fn optify(self) -> Option<T> {
        match self {
            Ok(t) => Some(t),
            Err(e) => {
                eprintln!("{e}");
                None
            }
        }
    }
}

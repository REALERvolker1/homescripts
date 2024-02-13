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
    #[error("Clap parsing error: {0}")]
    Clap(#[from] clap::error::Error),
    #[error("Invalid integer value: {0}")]
    InvalidInt(isize),

    // #[error("Error formatting toml: {0}")]
    // TomlSerialize(#[from] toml::ser::Error),
    #[error("Error editing/serializing toml: {0}")]
    TomlEditSerialize(#[from] toml_edit::ser::Error),
    // #[error("Error reading toml: {0}")]
    // TomlDeSerialize(#[from] toml::de::Error),
    #[error("Error editing/deserializing toml: {0}")]
    TomlEditDeSerialize(#[from] toml_edit::de::Error),

    /// An error type for hardcoded errors. This is why it is a static str
    #[error("Error: {0}")]
    KnownError(&'static str),
    /// An error type for errors that require string formatting. Try not to use this.
    #[error("Error: {0}")]
    Fmt(String),
    #[error("Unknown error occured")]
    Unknown,
}
impl From<()> for ModError {
    #[tracing::instrument(level = "debug")]
    fn from(_: ()) -> Self {
        Self::Unknown
    }
}
impl From<&'static str> for ModError {
    #[tracing::instrument(level = "debug")]
    fn from(value: &'static str) -> Self {
        Self::KnownError(value)
    }
}
impl From<String> for ModError {
    #[tracing::instrument(level = "debug")]
    fn from(value: String) -> Self {
        Self::Fmt(value)
    }
}
impl Into<zbus::Error> for ModError {
    #[tracing::instrument(skip_all, level = "debug")]
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

/// Determine if a gtk app exit should count as an error or not
pub fn glib_exit_code_to_mod_result(exit_code: glib::ExitCode) -> ModResult<()> {
    match exit_code {
        glib::ExitCode::SUCCESS => Ok(()),
        glib::ExitCode::FAILURE => Err(ModError::Fmt(format!(
            "glib error: return code {}",
            exit_code.value()
        ))),
        _ => Err(ModError::Fmt(format!("Unknown glib error: {exit_code:?}"))),
    }
}

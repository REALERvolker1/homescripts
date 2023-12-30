pub mod current_directory;
pub mod shell_env;
pub mod sudo;
pub mod timer;

pub mod hostname;
pub mod login;

use crate::{config, configlib, format};
use std::{env, error, fmt, io, path::*};

#[derive(Debug, Clone)]
pub enum UpdateType {
    String(String),
    Path(PathBuf),
    Int(usize),
    Bool(bool),
    Internal,
    None,
}
impl fmt::Display for UpdateType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::String(i) => write!(f, "{}", &i),
            Self::Path(i) => write!(f, "{}", &i.display()),
            Self::Int(i) => write!(f, "{}", i),
            Self::Bool(i) => write!(f, "{}", i),
            Self::Internal => write!(f, "Internal"),
            Self::None => write!(f, "None"),
        }
    }
}

#[derive(Debug)]
pub enum UpdateError {
    Environment(env::VarError),
    Io(io::Error),
    UpdateTypeError(UpdateType),
    Other(String),
    Any(Box<dyn error::Error>),
}
impl error::Error for UpdateError {}
impl fmt::Display for UpdateError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Environment(e) => write!(f, "Environment error: {}", e),
            Self::Io(e) => write!(f, "I/O error: {}", e),
            Self::UpdateTypeError(e) => write!(f, "Invalid update type: {}", e),
            Self::Other(e) => write!(f, "Error: {}", e),
            Self::Any(e) => write!(
                f,
                "AnyType error: {}\nPlease report this as a bug, you shouldn't ever see this!",
                e
            ),
        }
    }
}

#[derive(Debug)]
pub enum UpdateResult<T> {
    Ok(T),
    Err(UpdateError),
}

/// Shared functions for prompt segments
pub trait Module {
    // /// Initialize the value of the module
    // fn new() -> Option<Self> where Self: Sized;
    /// Get the format settings for the module
    fn format(&self) -> format::Format;
    /// Runtime check for whether the module should be shown.
    fn should_show(&self) -> bool;
}

pub trait DynamicModule {
    /// Update the value of the module
    fn update(&mut self, update_type: UpdateType) -> UpdateResult<()>;
}

/// Some modules don't have to be computed on every prompt.
pub trait ShellEnvModule {
    /// Some modules don't have to be computed on every prompt.
    /// This gets the currently defined string for the module.
    fn const_get(&self) -> format::Segment;
}

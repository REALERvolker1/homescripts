pub use ahash::{HashMap, HashMapExt};
pub use serde::{Deserialize, Serialize};
pub use smallvec::{SmallVec, ToSmallVec};

pub use std::{
    env, fmt, fs,
    io::{self, prelude::*},
    path::{Path, PathBuf},
    rc::Rc,
    simd::prelude::*,
    str::FromStr,
};

pub use nu_ansi_term::Color;

pub type R<T> = Result<T, crate::error::Err>;

pub trait Module {
    /// This is what is printed to the display.
    fn render(&self, config: crate::config::PrecmdConfig) -> String;
}

/// Modules that require shell code to be run at startup
#[const_trait]
pub trait ConstInitializer: Module {
    /// This is run on the shell initialization
    fn init() -> &'static str;
}

/// A wrapper around `precmd_functions`, run right before prompt is rendered
pub trait PreCmd: Module {
    type InputData;
    fn precmd(&mut self, input: Self::InputData);
}
/// A wrapper around `preexec_functions`, run right before command is executed
pub trait PreExec: Module {
    fn preexec(&mut self);
}
/// A wrapper around `chpwd_functions`, run when cwd is changed
pub trait ChPwd: Module {
    fn chpwd(&mut self);
}

pub trait ImplementsSerde<'de> = Serialize + Deserialize<'de>;

const ENV_VAR_PREFIX: &str = const_format::map_ascii_case!(const_format::Case::UpperSnake, NAME);

pub const NAME: &str = env!("CARGO_PKG_NAME");
pub const CONFIG_VAR: &str = const_format::concatcp!(ENV_VAR_PREFIX, "_CONFIG");

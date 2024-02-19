pub use crate::{action::ActionType, format::FormattedPath};
pub use clap::{Parser, ValueEnum};
pub use lscolors::LsColors;
pub use simple_eyre::eyre::{bail, eyre};
pub use std::{
    env, fmt, fs,
    io::{self, Write},
    path::{Path, PathBuf},
    sync::Arc,
};

pub type Res<T> = simple_eyre::Result<T>;

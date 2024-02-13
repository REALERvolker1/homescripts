pub mod argparse;
pub mod bar;
pub mod config;
pub mod modules;
pub mod runtime;
pub mod types;

pub(crate) use modules::Module;
pub(crate) use types::*;

pub(crate) use ahash::{HashMap, HashMapExt, HashSet, HashSetExt};
pub(crate) use clap::{Parser, ValueEnum};
pub(crate) use const_format::concatcp;
pub(crate) use futures_util::{Stream, StreamExt};
pub(crate) use gtk4::{self, gio, glib};
pub(crate) use if_chain::if_chain;
pub(crate) use itertools::Itertools;
pub(crate) use lazy_static::lazy_static;
// pub(crate) use parking_lot::{Mutex, RwLock};
pub(crate) use serde::{Deserialize, Serialize};
pub(crate) use smart_default::SmartDefault;
pub(crate) use std::{env, fmt, path::*, rc::Rc, str::FromStr, sync::Arc, time::Duration};
// pub(crate) use struct_field_names_as_array::FieldNamesAsSlice;
pub(crate) use strum::IntoEnumIterator;
pub(crate) use tokio::{
    fs, io, join, select,
    sync::mpsc::{self, Receiver, Sender},
    try_join,
};
pub(crate) use tracing::{debug, error, info, trace, warn};
pub(crate) use zbus::{zvariant, Connection, PropertyStream};

/// The name of the program
pub const NAME: &str = env!("CARGO_PKG_NAME");
/// The name of the program, but uppercase
pub const NAME_CAPS: &str = const_format::map_ascii_case!(const_format::Case::UpperSnake, NAME);

/// me
pub const AUTHOR: &str = "vlk";
/// The application ID for use in gtk and dbus
pub const APP_ID: &str = concatcp!("com.github.REALERvolker1.", NAME);

/// The environment variable used to override the config directory
pub const CONFIG_OVERRIDE: &str = concatcp!(NAME_CAPS, "_HOME");

/// Five seconds as a Duration
pub const FIVE_SECONDS: Duration = Duration::from_secs(5);

/// Async sleep using [`tokio::time::sleep`]. Returns a future.
#[macro_export]
macro_rules! sleep {
    ($time:expr) => {
        tokio::time::sleep($time)
    };
}

lazy_static! {
    pub static ref CONFIG: Arc<config::Config> = Arc::new(config::Config::new());
}

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    runtime::run().await
}

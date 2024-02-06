pub mod modules;
pub mod runtime;
pub mod types;

pub use modules::*;
pub use types::*;

use ahash::{HashMap, HashSet};
use gtk::{gio, glib};
use gtk::{prelude::*, Application, ApplicationWindow, Button, Entry, Label, Window};
use lazy_static::lazy_static;
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use std::{env, fmt, path::*, sync::Arc, time::Duration};
use tokio::{
    io,
    sync::mpsc::{self, Receiver, Sender},
    task::JoinHandle,
    time::sleep,
};
use zbus::zvariant::OwnedValue;

pub const APP_ID: &str = concat!("com.github.REALERvolker1.", env!("CARGO_PKG_NAME"));

/// A helpful macro for printing to the console only when `debug_assertions` is enabled
#[macro_export]
macro_rules! debug {
    ($($stuff:tt)+) => {
        #[cfg(debug_assertions)]
        println!($($stuff)+);
    };
}

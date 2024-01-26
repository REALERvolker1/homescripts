use crate::{backend::Backend, types::*, *};
use serde::{Deserialize, Serialize};
use std::{collections::HashSet, env, fmt, path::*, str::FromStr};
use strum::{EnumMessage, IntoEnumIterator};
use strum_macros::*;
use unicode_width::UnicodeWidthStr;

#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub touchpad_name: String,
    pub touchpad_key: String,
    pub mouse_names: String,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct Overrides {
    pub config_path: Option<PathBuf>,
    pub backend: Option<Backend>,
    pub action: Action,
    pub provided_args: Vec<String>,
}
impl Overrides {
    pub fn from_args() -> PResult<Self> {
        Self::from_vec(env::args().skip(1).collect())
    }
    /// literally just here for testing
    pub fn from_vec(args: Vec<String>) -> PResult<Self> {
        if args.is_empty() {
            // no need to parse anything
            return Ok(Self::default());
        }
        let mut iterator = args.iter();

        let mut me = Self::default();

        while let Some(arg) = iterator.next() {
            match arg.as_str() {
                "--override-config" => {
                    if let Some(p) = iterator.next() {
                        me.config_path = Some(PathBuf::from(p));
                    }
                }
                "--override-backend" => {
                    if let Some(s) = iterator.next() {
                        me.backend = Backend::from_str(s).ok();
                    }
                }
                _ => me.action = Action::from_str(arg).unwrap_or_default(),
            }
        }
        if me.action == Action::Help {
            return Err(PError::ArgParse(me.help()));
        }

        Ok(me)
    }
    /// Shows help text and panics.
    pub fn help(&self) -> String {
        format!(
            "{} [OPTIONS] ACTION

OPTIONS:

  \x1b[1m--override-config\x1b[0m    Choose an alternative config file

    The config path must be a .toml file. If the file does not exist, a default config will be created.
    Default: {}/{}/config.toml

  \x1b[1m--override-backend\x1b[0m   Choose the backend yourself,

    Useful for overriding the autodetected backend.
    Not recommended to set yourself. Use at your own risk.
    Available backends: [{}]

ACTIONS:

{}",
            env!("CARGO_BIN_NAME"),
            env::var("XDG_CONFIG_HOME").unwrap_or(String::from("~/.config")),
            config::CONFIG_NAME,
            Backend::iter()
                .map(|b| format!("{}", b))
                .collect::<Vec<_>>()
                .join(", "),
            Action::help()
        )
    }
}

#[derive(
    Debug,
    Clone,
    Copy,
    Serialize,
    Deserialize,
    Eq,
    Hash,
    PartialEq,
    Display,
    EnumIter,
    EnumString,
    EnumMessage,
)]
pub enum Flag {
    #[strum(message = "", detailed_message = "")]
    ConfigPath,
    #[strum(
        message = "Override the backend",
        detailed_message = "Not recommended to set yourself. Use at your own risk."
    )]
    OverrideBackend,
}

#[derive(
    Debug,
    Clone,
    Default,
    Eq,
    Hash,
    PartialEq,
    Serialize,
    Deserialize,
    Display,
    EnumString,
    EnumIter,
    EnumMessage,
)]
#[strum(serialize_all = "kebab-case")]
pub enum Action {
    #[strum(message = "Monitor the contents of the icon file")]
    MonitorIcon,
    #[strum(message = "Create a monitor that updates the status based on plug/unplug events")]
    StatusMonitor,

    #[strum(message = "Get the status icon")]
    GetIcon,
    #[strum(message = "Get the status text")]
    GetStatus,

    ///
    #[strum(message = "Manually toggle touchpad state")]
    Toggle,
    #[strum(message = "Enable the touchpad")]
    Enable,
    #[strum(message = "Disable the touchpad")]
    Disable,
    #[strum(
        message = "Determine the touchpad state from available devices and set or unset as needed"
    )]
    Normalize,
    #[default]
    Help,
}
impl Action {
    pub fn help() -> String {
        let params = Self::iter()
            .map(|s| {
                let s_str = format!("  \x1b[0;1m{s}\x1b[0m");
                let s_width = UnicodeWidthStr::width(s_str.as_str());
                (s_str, s.get_message(), s_width)
            })
            .collect::<Vec<_>>();

        let max_width = *params.iter().map(|(_, _, s)| s).max().unwrap_or(&0) + 2;

        params
            .into_iter()
            .map(|(s, m, w)| {
                if let Some(msg) = m {
                    format!("{:max_width$}  {msg}", s)
                } else {
                    s
                }
            })
            .collect::<Vec<_>>()
            .join("\n")
    }
    pub fn is_locking(&self) -> bool {
        match self {
            Self::StatusMonitor => true,
            _ => false,
        }
    }
}

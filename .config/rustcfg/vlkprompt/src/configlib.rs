use crate::format::*;
use std::env;

/// All the formatting required for the Cwd segment and its various states
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CwdFormatConfig {
    /// Current directory is a symlink
    pub lnk: Format,
    /// Current directory is a read-only symlink
    pub lnk_ro: Format,
    /// Current directory is a regular directory
    pub reg: Format,
    /// Current directory is a read-only regular directory
    pub reg_ro: Format,
    /// Current directory is the `$HOME (~)` directory. Should not be read-only
    pub home: Format,
}

/// The icon config for powerline icons
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PowerlineIconConfig {
    /// The icon for the very end, the last segment
    pub end: Icon,
    /// The icon for the end in special circumstances. Implementation varies on which prompt you're in
    pub end_special: Icon,
    /// The icon to separate segments from each other
    pub separator: Icon,
    /// The icon to separate multiple parts of the same segment
    pub internal_separator: Icon,
}

/// The hardcoded formatting configuration
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MainFormatConfig {
    /// Format for the current directory
    pub cwd: CwdFormatConfig,
    /// Format for both the git segment and current directory git segment
    pub git: Format,
    /// Format for the vicmd mode segment
    pub vim: Format,
    /// Format for the error code segment
    pub err: Format,
    /// Format for the jub numbers segment
    pub job: Format,
    /// Format for the timer segment
    pub timer: Format,
    // /// Format for the changed environment variable segment 󰫧
    // pub env: Format,
    /// Format for the distrobox container segment
    pub distrobox: Format,
    /// If the hostname does not equal `$VLKPROMPT_DEFAULT_HOSTNAME`, this segment is shown
    pub host: Format,
    /// If the shell is in an ssh session
    pub ssh: Format,
    /// If the shell is a login shell
    pub login: Format,
    /// TODO: Actually test this
    pub nix: Format,
    /// If you're in an anaconda environment. Remember to set `changeps1: false` in your condarc
    pub conda: Format,
    /// The python venv string. The init script will set `$VIRTUAL_ENV_DISABLE_PROMPT` so the default is not shown.
    pub venv: Format,
    /// The powerline icons for the `RPROMPT` <<prompt < foo
    pub pline_r: PowerlineIconConfig,
    /// The powerline config for the regular `PROMPT` foo > PROMPT >>
    pub pline_l: PowerlineIconConfig,
}

/// A static config environment variable
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EnvConfigType {
    /// The name of the environment variable
    pub key: &'static str,
    /// The value to use when it is not defined
    pub default: &'static str,
}
impl EnvConfigType {
    /// Get the value from the environment, or return the default
    pub fn get(&self) -> String {
        if let Ok(e) = env::var(self.key) {
            e
        } else {
            self.default.to_string()
        }
    }
    /// Sorta like `get()`, but initializes this value for use in a `static`
    pub fn get_or_default(key: &str, default: &str) -> String {
        if let Ok(e) = env::var(key) {
            e
        } else {
            default.to_string()
        }
    }
    /// Sorta like `get_or_default()`, but falls back to an empty string
    pub fn get_or_empty(key: &str) -> String {
        if let Ok(e) = env::var(key) {
            e
        } else {
            String::new()
        }
    }
}

/// The environment variables that are used to configure this at runtime
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EnvConfig {
    /// The default hostname, used to determine if the host segment should be shown
    pub default_hostname: String,
}

pub fn env_exists(key: &str) -> bool {
    if let Ok(current) = env::var(key) {
        if current.is_empty() {
            false
        } else {
            true
        }
    } else {
        false
    }
}

/// An environment variable
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EnvVar {
    /// The name of the environment variable
    pub name: String,
    /// the current value. if it is actually set, it is Some, otherwise it is not shown.
    pub value: Option<String>,
}
impl EnvVar {
    /// Set the value of the environment variable to what it is in the environment right now
    pub fn refresh(&mut self) {
        self.value = Self::value_from_key(&self.name)
    }
    /// Get the value of an environment variable and return a representation of it
    pub fn new(key: &str) -> Self {
        Self {
            name: key.to_owned(),
            value: Self::value_from_key(key),
        }
    }
    /// Get the value of a key from the environment
    fn value_from_key(key: &str) -> Option<String> {
        if let Ok(current) = env::var(key) {
            if current.is_empty() {
                None
            } else {
                Some(current)
            }
        } else {
            None
        }
    }
    /// A function to use if you just want to check if an env variable is set, not necessarily get what it is
    pub fn is_in_env(key: &str) -> bool {
        Self::value_from_key(key).is_some()
    }
    /// A shortcut to check if self is set. Make sure to refresh first!
    pub fn is_set(&self) -> bool {
        self.value.is_some()
    }
}

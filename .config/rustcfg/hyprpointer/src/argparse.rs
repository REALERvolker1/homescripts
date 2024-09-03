use std::{
    fmt::Write,
    io::{self, StdoutLock},
    str::FromStr,
};

use strum::{EnumCount, EnumMessage, VariantArray};

pub const DEFAULT_MICE: &[&[u8]] = &[b"glorious", b"logitech", b"razer"];

pub struct Args {
    pub is_verbose: bool,
    pub is_silent: bool,
    pub mouse_names: Vec<Vec<u8>>,
    pub action: Option<AppAction>,
}
impl Default for Args {
    fn default() -> Self {
        Self {
            is_verbose: false,
            is_silent: false,
            mouse_names: DEFAULT_MICE.into_iter().cloned().map(Vec::from).collect(),
            action: None,
        }
    }
}
impl Args {
    pub fn parse() -> Result<Self, ArgParseError> {
        todo!();
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct ArgInfo {
    long: &'static str,
    short: char,
    data_type: Option<AppArgDiscriminants>,
    help: &'static str,
}
impl ArgInfo {
    #[inline]
    pub const fn new(
        long: &'static str,
        short: char,
        data_type: Option<&'static str>,
        help: &'static str,
    ) -> Self {
        Self {
            long,
            short,
            data_type,
            help,
        }
    }

    pub fn write_fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "  \x1b[1m--{}\x1b[0m (\x1b[1m-{}\x1b[0m)",
            self.long, self.short
        )?;

        let mut pad_width = (AppArg::STATIC_INFO_PAD_LEN + 2) - self.pad_length();

        if let Some(dt) = self.data_type {
            write!(f, " <{}>", dt)?;
        }

        for _ in 0..pad_width {
            f.write_char(' ')?;
        }

        f.write_str(&self.help)?;

        Ok(())
    }

    pub const fn pad_length(&self) -> usize {
        self.long.len()
            + match self.data_type {
                Some(dt) => dt.as_ref().len() + 3,
                None => 0,
            }
            + 4
    }
}

macro_rules! find_const_widths {
    ($arr:expr, $lenfn:ident) => {
        {
            let mut max = 0;

            konst::iter::for_each!(i in $arr => {
                let len = i.$lenfn();
                if len > max {
                    max = len;
                }
            });

            max
        }
    };
}
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, strum_macros::EnumCount, strum_macros::EnumDiscriminants,
)]
#[strum_discriminants(derive(strum_macros::VariantNames, strum_macros::VariantArray, strum_macros::Display, strum_macros::AsRefStr))]
#[strum_discriminants(strum(serialize_all = "UPPERCASE"))]
pub enum AppArg {
    Verbose,
    Quiet,
    Action(AppAction),
    Help,
}
impl AppArg {
    const STATIC_INFO: [ArgInfo; AppArg::COUNT] = [
        ArgInfo::new("verbose", 'v', None, "Print verbose messages"),
        ArgInfo::new("quiet", 'q', None, "Print only errors"),
        ArgInfo::new("action", 'a', Some("ACTION"), "Run an action"),
        ArgInfo::new("help", 'h', None, "Print this help message"),
    ];

    const STATIC_INFO_PAD_LEN: usize = find_const_widths!(Self::STATIC_INFO.as_slice(), pad_length);

    /// TODO: Enum discriminants
    fn interpret_data_type(next: &str, data_type: &'static str) -> Result<Self, ArgParseError> {
        match data_type {
            "ACTION" => {
                let action =
                    AppAction::from_str(next).map_err(|_| ArgParseError::InvalidData(data_type))?;
                Ok(Self::Action(action))
            }
            _ => unreachable!("Invalid data type: {data_type}"),
        }
    }

    fn try_parse_arg(arg: &str, next: Option<&str>) -> Result<Self, ArgParseError> {
        if arg.starts_with("--") {
            let arg = &arg[2..];
            let Some(info) = Self::STATIC_INFO.iter().find(|i| i.long == arg) else {
                return Err(ArgParseError::InvalidArg(arg.to_string()));
            };

            match info.data_type {
                Some(d) => {
                    let next = next.ok_or_else(|| ArgParseError::MissingData(info.long, d))?;
                    return Self::interpret_data_type(next, d);
                }
                None => return Self::
            }
        }

        todo!();
    }
}

#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    strum_macros::EnumString,
    strum_macros::Display,
    strum_macros::AsRefStr,
    strum_macros::EnumMessage,
    strum_macros::VariantArray,
    strum_macros::VariantNames,
)]
#[strum(serialize_all = "kebab-case")]
pub enum AppAction {
    #[strum(message = "Monitor the current state, printing an icon to stdout")]
    MonitorIcon,
    #[strum(
        message = "Watch for devices being added or removed, and toggle the touchpad accordingly"
    )]
    WatchDevices,

    #[strum(message = "Query the current state of the touchpad")]
    Query,

    #[strum(message = "Normalize the touchpad's state (disable on mouse, otherwise enable)")]
    Normalize,
    #[strum(message = "Toggle the touchpad on or off")]
    Toggle,
    #[strum(message = "Enable the touchpad")]
    Enable,
    #[strum(message = "Disable the touchpad")]
    Disable,
}
impl AppAction {
    #[inline]
    pub const fn requires_hyprctl(&self) -> bool {
        match self {
            Self::MonitorIcon => false,
            Self::WatchDevices
            | Self::Query
            | Self::Normalize
            | Self::Toggle
            | Self::Enable
            | Self::Disable => true,
        }
    }

    pub const PAD_LEN: usize = find_const_widths!(<Self as strum::VariantNames>::VARIANTS, len);

    pub fn write_fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let me_string: &str = self.as_ref();
        write!(f, "  \x1b[1m{}\x1b[0m", me_string)?;

        for _ in 0..(Self::PAD_LEN - me_string.len()) + 2 {
            f.write_char(' ')?;
        }

        write!(f, "  {}", self.get_message().unwrap_or_default())?;

        Ok(())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum ArgParseError {
    #[error("Only one of VERBOSE or QUIET can be specified")]
    VerboseQuiet,
    #[error("Invalid argument passed: {0}")]
    InvalidArg(String),
    #[error("Invalid argument of type {0}")]
    InvalidData(&'static str),
    #[error("Missing argument for {0} of type: {1}")]
    MissingData(&'static str, &'static str),
}
impl ArgParseError {
    #[inline]
    pub fn print_help(&self, out: &mut StdoutLock) -> io::Result<()> {
        print_help(out, Some(self.clone()))
    }
}

/// This is here because I needed to write something that takes std::fmt::Write into something with std::io::Write.
struct HelpPrinter(Option<ArgParseError>);
impl std::fmt::Display for HelpPrinter {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if let Some(ref err) = self.0 {
            writeln!(f, "\x1b[0m{err}\n")?;
        }

        writeln!(f, "Available arguments:")?;

        for arg in AppArg::STATIC_INFO {
            arg.write_fmt(f)?;
            writeln!(f, "")?;
        }

        writeln!(f, "")?;

        writeln!(f, "Available actions:")?;

        for action in AppAction::VARIANTS {
            action.write_fmt(f)?;
            writeln!(f, "")?;
        }

        Ok(())
    }
}

#[inline]
pub fn print_help(out: &mut StdoutLock, err: Option<ArgParseError>) -> io::Result<()> {
    use std::io::Write;
    writeln!(out, "{}", HelpPrinter(err))
}

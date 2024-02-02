use crossterm::style::Stylize;

use crate::*;

/// Debug-print something. Only works in debug builds.
#[macro_export]
macro_rules! debug {
    ($($arg:tt)+) => {
        #[cfg(debug_assertions)]
        eprintln!($($arg)+);
    };
}

pub const PID_NULL: Pid = Pid { raw: 0 };
pub const ROOT_UID: Uid = Uid { raw: 0 };

lazy_static! {
    pub static ref BOLD: ContentStyle = Style::new().reset().bold();
    pub static ref MY_UID: Uid = unistd::getuid().into();
    pub static ref MY_PID: Pid = unistd::getpid().into();
    pub static ref LS_COLORS: LsColors = LsColors::from_env().unwrap_or_default();
    pub static ref ARGS: cli::Args = cli::Args::parse();
}

/// Make a string bold, all other styles cleared
#[macro_export]
macro_rules! bold {
    ($str:expr) => {
        BOLD.apply($str)
    };
}

/// Check if it is a debug build
pub const IS_DEBUG: bool = cfg!(debug_assertions);

pub type Bruh<T> = ::std::result::Result<T, BruhMoment>;
#[derive(Debug, derive_more::From, derive_more::Display, thiserror::Error)]
pub enum BruhMoment {
    #[display(fmt = "IO error received: {}", _0)]
    Io(io::Error),
    #[display(fmt = "Environment variable error: {}", _0)]
    Env(env::VarError),
    #[display(fmt = "Process error: {}", _0)]
    Procfs(procfs::ProcError),
    #[display(fmt = "System error: {}", _0)]
    NixErrno(nix::errno::Errno),
    Filter,
    #[display(fmt = "Invalid user uid: {}", _0)]
    InvalidUser(Uid),
    #[display(fmt = "Error: {}", _0)]
    Other(String),
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash)]
pub enum RecognizedStates {
    Zombie,
    Running,
    Idle,
    Sleeping,
    DiskSleep,
    #[default]
    Unknown,
}
impl RecognizedStates {
    pub fn from_str(s: &str) -> RecognizedStates {
        match s {
            "R" => Self::Running,
            "S" => Self::Sleeping,
            "D" => Self::DiskSleep,
            "I" => Self::Idle,
            "Z" => Self::Zombie,
            _ => Self::Unknown,
        }
    }
    pub fn color(&self) -> Color {
        match self {
            Self::Running => Color::Green,
            Self::Sleeping => Color::Cyan,
            Self::DiskSleep => Color::DarkCyan,
            Self::Idle => Color::Yellow,
            Self::Zombie => Color::DarkRed,
            Self::Unknown => Color::DarkMagenta,
        }
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash, strum_macros::Display)]
pub enum StatusState {
    Good,
    Warn,
    Bad,
    Critical,
    #[default]
    None,
}
impl StatusState {
    pub fn color(&self) -> Color {
        match self {
            Self::Good => Color::Green,
            Self::Warn => Color::DarkYellow,
            Self::Bad => Color::Red,
            Self::Critical => Color::DarkRed,
            Self::None => Color::DarkCyan,
        }
    }
}

pub trait NixIdTypeWrapper: Clone + Copy + From<Self::Wraps> + From<Self::Inner> {
    type Inner;
    type Wraps;
    fn as_raw(&self) -> Self::Inner;
}

#[derive(
    Debug, Default, Clone, Copy, PartialEq, Eq, Hash, derive_more::Display, PartialOrd, Ord,
)]
pub struct Pid {
    raw: i32,
}
impl From<unistd::Pid> for Pid {
    fn from(value: unistd::Pid) -> Self {
        Pid {
            raw: value.as_raw(),
        }
    }
}
impl From<i32> for Pid {
    fn from(value: i32) -> Self {
        Pid { raw: value }
    }
}
impl Into<unistd::Pid> for Pid {
    fn into(self) -> unistd::Pid {
        unistd::Pid::from_raw(self.raw)
    }
}
impl NixIdTypeWrapper for Pid {
    type Inner = i32;
    type Wraps = unistd::Pid;
    fn as_raw(&self) -> Self::Inner {
        self.raw
    }
}

#[derive(
    Debug, Default, Clone, Copy, PartialEq, Eq, Hash, derive_more::Display, PartialOrd, Ord,
)]
pub struct Uid {
    raw: u32,
}

impl From<unistd::Uid> for Uid {
    fn from(value: unistd::Uid) -> Self {
        Uid {
            raw: value.as_raw(),
        }
    }
}
impl Into<unistd::Uid> for Uid {
    fn into(self) -> unistd::Uid {
        unistd::Uid::from_raw(self.raw)
    }
}
impl From<u32> for Uid {
    fn from(value: u32) -> Self {
        Uid { raw: value }
    }
}
impl NixIdTypeWrapper for Uid {
    type Inner = u32;
    type Wraps = unistd::Uid;
    fn as_raw(&self) -> Self::Inner {
        self.raw
    }
}

use crate::*;

/// Debug-print something. Only works in debug builds.
#[macro_export]
macro_rules! debug {
    ($($arg:tt)+) => {
        #[cfg(debug_assertions)]
        eprintln!($($arg)+);
    };
}
pub static PID_NULL: Pid = Pid::from_raw(0);

lazy_static! {
    pub static ref BOLD: Style = Style::new().reset_before_style().bold();
    pub static ref MY_UID: Uid = unistd::getuid();
    pub static ref LS_COLORS: LsColors = LsColors::from_env().unwrap_or_default();
    pub static ref ARGS: cli::Args = cli::Args::parse();
}

/// Make a string bold, all other styles cleared
#[macro_export]
macro_rules! bold {
    ($str:expr) => {
        BOLD.paint($str)
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
    #[display(fmt = "Error: {}", _0)]
    Other(String),
}

// impl From<io::Error> for BruhMoment {
//     fn from(err: io::Error) -> Self {
//         BruhMoment::Io(err)
//     }
// }
// impl From<env::VarError> for BruhMoment {
//     fn from(err: env::VarError) -> Self {
//         BruhMoment::Env(err)
//     }
// }
// impl From<procfs::ProcError> for BruhMoment {
//     fn from(err: procfs::ProcError) -> Self {
//         BruhMoment::Procfs(err)
//     }
// }
// impl From<nix::errno::Errno> for BruhMoment {
//     fn from(err: nix::errno::Errno) -> Self {
//         BruhMoment::NixErrno(err)
//     }
// }

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
            Self::Running => Color::LightGreen,
            Self::Sleeping => Color::LightCyan,
            Self::DiskSleep => Color::Cyan,
            Self::Idle => Color::LightYellow,
            Self::Zombie => Color::Red,
            Self::Unknown => Color::Magenta,
        }
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash)]
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
            Self::Good => Color::LightGreen,
            Self::Warn => Color::Yellow,
            Self::Bad => Color::Red,
            Self::Critical => Color::LightRed,
            Self::None => Color::Cyan,
        }
    }
}

use crate::style;
use nu_ansi_term::Style;
use procfs;
use serde::{Deserialize, Serialize};
use serde_json;
use static_init::dynamic;
use std::{collections::HashMap, env, error, fmt::Display, io, rc::Rc, sync::Arc};
use users::{self, Users};
///! Future readers may wonder why I made this a separate module. This is because proc.rs is very long and I want it to
///! be as easy to read as possible despite its complexity.

pub trait Styler {
    fn to_nu_ansi_term_style(&self) -> Style;
}
pub trait Painterly {
    fn paint(&self) -> String;
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Deserialize, Serialize)]
pub enum RecognizedStates {
    Zombie,
    Running,
    Idle,
    Sleeping,
    DiskSleep,
    #[default]
    Unknown,
}
impl From<&str> for RecognizedStates {
    fn from(s: &str) -> Self {
        match s {
            "R" => Self::Running,
            "S" => Self::Sleeping,
            "D" => Self::DiskSleep,
            "I" => Self::Idle,
            "Z" => Self::Zombie,
            _ => Self::Unknown,
        }
    }
}
impl Painterly for RecognizedStates {
    fn paint(&self) -> String {
        let myself = format!("{:?}", self);
        format!("{}", self.to_nu_ansi_term_style().paint(myself))
    }
}
impl Styler for RecognizedStates {
    /// Should be used to color the program name (argzero)
    fn to_nu_ansi_term_style(&self) -> Style {
        match self {
            Self::Running => style::COLOR_CONFIG.state_running_color,
            Self::Sleeping => style::COLOR_CONFIG.state_sleeping_color,
            Self::DiskSleep => style::COLOR_CONFIG.state_disksleep_color,
            Self::Idle => style::COLOR_CONFIG.state_idle_color,
            Self::Zombie => style::COLOR_CONFIG.state_zombie_color,
            Self::Unknown => style::COLOR_CONFIG.state_unknown_color,
        }
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Deserialize, Serialize)]
pub enum FilterType {
    Root,
    User,
    OtherUser,
    #[default]
    Unknown,
}
impl Styler for FilterType {
    /// Should be used to color the PID
    fn to_nu_ansi_term_style(&self) -> Style {
        match self {
            Self::Root => style::COLOR_CONFIG.root_color,
            Self::User => style::COLOR_CONFIG.user_color,
            Self::OtherUser => style::COLOR_CONFIG.other_user_color,
            Self::Unknown => style::COLOR_CONFIG.unknown_user_color,
        }
    }
}

#[derive(Debug)]
pub enum UserErrorType {
    NonExistent,
    MatchFilter,
    GetCurrentUserError,
    Other,
}

#[derive(Debug)]
pub enum ProcError {
    IoError(io::Error),
    ProcError(procfs::ProcError),
    SerdeJsonError(serde_json::Error),
    EnvironmentError(env::VarError),
    PathBinaryError(String),
    CustomError(String),
    Unknown,
}
impl error::Error for ProcError {}
impl Display for ProcError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::IoError(e) => write!(f, "IoError: {}", e),
            Self::ProcError(e) => write!(f, "ProcError: {}", e),
            Self::SerdeJsonError(e) => write!(f, "SerdeJsonError: {:?}", e),
            Self::EnvironmentError(e) => write!(f, "EnvironmentError: {}", e),
            Self::PathBinaryError(e) => write!(f, "Missing required commands: {}", e),
            Self::CustomError(e) => write!(f, "Error: {}", e),
            Self::Unknown => write!(f, "Unknown"),
        }
    }
}
impl From<procfs::ProcError> for ProcError {
    fn from(e: procfs::ProcError) -> Self {
        Self::ProcError(e)
    }
}
impl From<io::Error> for ProcError {
    fn from(e: io::Error) -> Self {
        Self::IoError(e)
    }
}
impl From<serde_json::Error> for ProcError {
    fn from(e: serde_json::Error) -> Self {
        Self::SerdeJsonError(e)
    }
}
impl From<env::VarError> for ProcError {
    fn from(e: env::VarError) -> Self {
        Self::EnvironmentError(e)
    }
}

#[dynamic]
pub static USER: Arc<User> = Arc::new(User::me());

/// My serde-friendly version of user::User that has everything I need
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct User {
    pub name: String,
    pub uid: u32,
    pub filter_type: FilterType,
}
impl Default for User {
    fn default() -> Self {
        Self {
            name: "".to_owned(),
            uid: 69420,
            filter_type: FilterType::Unknown,
        }
    }
}
impl Painterly for User {
    fn paint(&self) -> String {
        self.to_nu_ansi_term_style()
            .paint(format!("{} ({})", self.name, self.uid))
            .to_string()
    }
}
impl Styler for User {
    fn to_nu_ansi_term_style(&self) -> Style {
        self.filter_type.to_nu_ansi_term_style()
    }
}
impl User {
    /// Gets the current user. It is called by a static init macro.
    fn me() -> Self {
        let my_uid = users::get_current_uid();
        // if your user doesn't exist, that's a skill issue. Try harder.
        Self::from_uid(my_uid).unwrap()
    }
    pub fn from_uid(uid: u32) -> Option<Self> {
        if let Some(my_user) = users::get_user_by_uid(uid) {
            Some(User {
                name: my_user.name().to_string_lossy().to_string(),
                uid: uid,
                filter_type: FilterType::User,
            })
        } else {
            None
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct UserList {
    pub me: User,
    pub users: HashMap<u32, Rc<User>>,
}
impl Default for UserList {
    fn default() -> Self {
        Self {
            me: User::default(),
            users: HashMap::new(),
        }
    }
}
impl UserList {
    /// Get a UserList that only contains the current user
    pub fn just_me() -> Self {
        let my_user = Rc::new(User::me());
        let mut myhashmap = HashMap::new();
        myhashmap.insert(my_user.uid, Rc::clone(&my_user));
        Self {
            me: my_user.as_ref().to_owned(),
            users: myhashmap,
        }
    }
    /// Get a UserList that contains all the users on the system
    pub fn all() -> Self {
        let mut userlist = HashMap::new();
        // first time I actually need to use an unsafe block lmao
        unsafe {
            for user in users::all_users() {
                let uid = user.uid();
                let filter = if uid == 0 {
                    FilterType::Root
                } else {
                    FilterType::OtherUser
                };

                let user = User {
                    name: user.name().to_string_lossy().to_string(),
                    uid,
                    filter_type: filter,
                };
                userlist.insert(uid, Rc::new(user));
            }
        }
        Self {
            me: User::me(),
            users: userlist,
        }
    }
    pub fn get_user(&self, uid: u32) -> Option<Rc<User>> {
        if let Some(user) = self.users.get(&uid) {
            Some(Rc::clone(user))
        } else {
            None
        }
    }
}

use crate::{command, style};
use lscolors::LsColors;
// use lazy_static::lazy_static;
use nu_ansi_term::Style;
use procfs;
use serde::{Deserialize, Serialize};
use static_init::{self, dynamic};
use std::{
    collections::HashMap,
    env, error,
    fmt::Display,
    io,
    path::{Path, PathBuf},
    process,
    rc::Rc,
    sync::{Arc, Mutex},
};
use users;

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
impl RecognizedStates {
    pub fn to_nu_ansi_term_style(&self) -> Style {
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
impl FilterType {
    pub fn to_nu_ansi_term_style(&self) -> Style {
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
    UserError(UserErrorType),
    StatError,
    StatusError,
    Unknown,
}
impl error::Error for ProcError {}
impl Display for ProcError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::IoError(e) => write!(f, "IoError: {}", e),
            Self::ProcError(e) => write!(f, "ProcError: {}", e),
            Self::UserError(e) => write!(f, "UserError: {:?}", e),
            Self::StatError => write!(f, "StatError"),
            Self::StatusError => write!(f, "StatusError"), // unused
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

#[dynamic]
pub static USER: Arc<User> = Arc::new(User::me());

// #[dynamic]
// pub static USER_LIST: Arc<UserList> = Arc::new(UserList::all());
// #[dynamic]
// pub static mut COMPUTED_USERS: Arc<Mutex<HashMap<u32, Arc<User>>>> =
//     Arc::new(Mutex::new(HashMap::new()));

/// My serde-friendly version of user::User that has everything I need
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct User {
    name: String,
    uid: u32,
    filter_type: FilterType,
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
impl User {
    /// Gets the current user. It is called by a static init macro.
    fn me() -> Self {
        let my_uid = users::get_current_uid();
        let my_user = users::get_user_by_uid(my_uid).unwrap();
        User {
            name: my_user.name().to_string_lossy().to_string(),
            uid: my_uid,
            filter_type: FilterType::User,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct UserList {
    pub me: User,
    pub users: HashMap<u32, User>,
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
    pub fn just_me() -> Self {
        Self {
            me: User::me(),
            users: HashMap::new(),
        }
    }
    pub fn all() -> Self {
        let my_uid = users::get_current_uid();

        let mut userlist = HashMap::new();
        // first time I actually need to use an unsafe block lmao
        unsafe {
            for user in users::all_users() {
                let uid = user.uid();
                let filter = match uid {
                    0 => FilterType::Root,
                    my_uid => FilterType::User,
                    _ => FilterType::OtherUser,
                };

                let user = User {
                    name: user.name().to_string_lossy().to_string(),
                    uid,
                    filter_type: filter,
                };
                userlist.insert(uid, user);
            }
        }
        Self {
            me: User::me(),
            users: userlist,
        }
    }
    pub fn get_user(&self, uid: u32) -> Option<User> {
        Some(self.users.get(&uid)?.clone())
    }
    pub fn get_filtertype(&self, uid: u32) -> Option<FilterType> {
        Some(self.users.get(&uid)?.filter_type)
    }
}

macro_rules! style_args_default {
    ($arg:expr) => {
        Rc::new(style::COLOR_CONFIG.args_color.paint($arg).to_string())
    };
    ($arg:expr, norc) => {
        style::COLOR_CONFIG.args_color.paint($arg).to_string()
    };
}

macro_rules! unrc {
    ($rc:expr) => {
        $rc.as_ref().to_owned()
    };
}

pub struct StyleCache {
    pub color_path_cache: HashMap<Rc<String>, Rc<String>>,
    pub ls_colors: LsColors,
}
impl Default for StyleCache {
    fn default() -> Self {
        Self {
            color_path_cache: HashMap::new(),
            ls_colors: LsColors::from_env().unwrap_or_default(),
        }
    }
}
impl StyleCache {
    pub fn get_styled_string(&mut self, arg: &str) -> String {
        // Since I'm trying to avoid doing bareback clones, I have decided to learn how to use
        // Rc types. This is why I am writing clone() all over the place, I'm pretty sure it
        // just points to the same pointer in memory
        let argrc = Rc::new(arg.to_owned());
        let output = if let Some(cached) = self.color_path_cache.get(&argrc) {
            cached.clone()
        } else if let Some(slash_index) = arg.find("/") {
            let (left, right) = arg.split_at(slash_index);
            let left = self.get_styled_string(left);
            let right_rc = Rc::new(right.to_owned());

            let styled_path = if let Some(right_string) = self.color_path_cache.get(&right_rc) {
                right_string.clone()
            } else {
                let right_style = self.ls_colors.style_for_path_components(Path::new(right));
                let right_vec = right_style
                    .map(|(str, style_opt)| {
                        let segment = str.to_string_lossy();
                        if let Some(style) = style_opt {
                            style.to_nu_ansi_term_style().paint(segment).to_string()
                        } else {
                            style_args_default!(segment, norc)
                        }
                    })
                    .collect::<Vec<String>>();
                let right_result = Rc::new(right_vec.join(""));

                self.color_path_cache
                    .insert(right_rc.clone(), right_result.clone());

                right_result.clone()
            };

            let stylestr = Rc::new(format!("{}{}", left, styled_path));
            self.color_path_cache
                .insert(argrc.clone(), stylestr.clone());
            stylestr
        } else {
            let styled = style_args_default!(arg);
            self.color_path_cache.insert(argrc.clone(), styled.clone());
            styled
        };
        unrc!(output)
    }
}

#[derive(Debug, PartialEq, Deserialize, Serialize)]
pub struct Proc {
    name: String,
    state: RecognizedStates,
    filter_type: FilterType,
    pid: i32,
    ppid: i32,
    args: Vec<String>,
    is_styled: bool,
}
impl Default for Proc {
    fn default() -> Self {
        Self {
            name: "".to_string(),
            state: RecognizedStates::Unknown,
            filter_type: FilterType::OtherUser,
            pid: -1,
            ppid: -1,
            args: Vec::new(),
            is_styled: false,
        }
    }
}
impl Proc {
    pub fn from_procfs_proc(
        procfs_process: procfs::process::Process,
        show_all: bool,
        user_cache: &UserList,
        style_cache: &mut StyleCache,
        my_uid: u32,
        approximate_preferred_width: usize,
    ) -> Result<Proc, ProcError> {
        // do uid filtering first, make sure we need to show it or not before computing all this
        let uid = procfs_process.uid()?;
        let filter_type = if uid == my_uid {
            FilterType::User
        } else if !show_all {
            user_cache.get_filtertype(uid).unwrap_or_default()
        } else {
            // should be unreachable
            return Err(ProcError::UserError(UserErrorType::MatchFilter));
        };

        let my_pid = procfs_process.pid();

        let (parent_pid, name, state) = if let Ok(status) = procfs_process.status() {
            let stat_state = status.state.as_str();
            let my_state = stat_state.split_at(stat_state.find(" ").unwrap_or(1)).0;
            (status.ppid, status.name, RecognizedStates::from(my_state))
        } else {
            (-1, "".to_owned(), RecognizedStates::Unknown)
        };

        let mut args = procfs_process.cmdline().unwrap_or_default();
        if let Some(first) = args.first() {
            if let Ok(binary) = procfs_process.exe() {
                let binary_string = binary.to_string_lossy().to_string();
                if first != &binary_string {
                    args[0] = format!("({})", first);
                    args.insert(0, binary_string);
                }
            }
        }

        if args.is_empty() {
            args.push("(-)".to_owned()); // to make it look a bit more like `ps(1)`
        }
        let mut styled_args = Vec::new();

        // Make sure we don't overflow the terminal with useless garbage args
        let mut line_length = 0;
        for arg in args.iter() {
            if line_length < approximate_preferred_width {
                let arg_length = arg.chars().count();
                styled_args.push(style_cache.get_styled_string(arg));
                line_length = line_length + arg_length;
            }
        }

        Ok(Self {
            name,
            state,
            filter_type,
            pid: my_pid,
            ppid: parent_pid,
            args: styled_args,
            is_styled: false,
        })
    }
    pub fn console_style(&self) -> String {
        format!("{}\t{}\t{}", self.pid, self.name, self.args.join(" "))
    }
    // pub fn tui_style(
    //     &mut self,
    //     color_path_cache: &mut HashMap<&str, Rc<String>>,
    //     ls_colors: LsColors,
    // ) -> () {
    //     // skip if already styled
    //     if self.is_styled {
    //         return ();
    //     }
    //     let styled_args: Vec<String> = self
    //         .args
    //         .iter()
    //         .map(|arg| {
    //             let rcarg = Rc::new(arg);
    //             let rc_result = if let Some(colored_arg) = color_path_cache.get(rcarg.as_str()) {
    //                 colored_arg.to_owned()
    //             } else {
    //                 let path = Path::new(rcarg.as_ref());
    //                 let styled_arg = if path.exists() {
    //                     let mut filepath = Vec::new();
    //                     for (osstring, opt_style) in ls_colors.style_for_path_components(path) {
    //                         let style = if let Some(lscolors_style) = opt_style {
    //                             lscolors_style.to_nu_ansi_term_style()
    //                         } else {
    //                             style::COLOR_CONFIG.args_color
    //                         };

    //                         filepath.push(style.paint(osstring.to_string_lossy()).to_string());
    //                     }
    //                     let completed_arg = Rc::new(filepath.join(""));
    //                     color_path_cache.insert(rcarg.as_str(), completed_arg.clone());
    //                     completed_arg
    //                 } else {
    //                     style_args_default!(rcarg.as_str())
    //                     // Rc::new(
    //                     //     style::COLOR_CONFIG
    //                     //         .args_color
    //                     //         .paint(rcarg.as_str())
    //                     //         .to_string(),
    //                     // )
    //                 };
    //                 styled_arg
    //             };
    //             unrc!(rc_result)
    //             // get it out of the Rc
    //         })
    //         .collect::<Vec<String>>();
    //     self.args = styled_args;

    //     self.is_styled = true;
    // }
}

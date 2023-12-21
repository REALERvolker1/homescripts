use crate::{
    command,
    procinfo::{self, Painterly, Styler},
    style,
};
use lscolors::LsColors;

use procfs;
use serde::{Deserialize, Serialize};
use std::{
    collections::HashMap,
    path::{Path, PathBuf},
    rc::Rc,
    sync::Arc,
};

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
    pub name_format_cache: HashMap<Rc<String>, Rc<String>>,
    pub args_format_cache: HashMap<Rc<String>, Rc<String>>,
    pub ls_colors: LsColors,
}
impl Default for StyleCache {
    fn default() -> Self {
        Self {
            name_format_cache: HashMap::new(),
            args_format_cache: HashMap::new(),
            ls_colors: LsColors::from_env().unwrap_or_default(),
        }
    }
}
impl StyleCache {
    /// This function gets a styled arg and returns it. It uses a cache. It is fast, but uses more memory.
    pub fn get_styled_arg(&mut self, arg: &str) -> String {
        // Since I'm trying to avoid doing bare clones, I have decided to learn how to use
        // Rc types. This is why I am writing Rc::clone all over the place, I'm pretty sure it
        // just points to the same pointer in memory while acting like an owned value.
        let argrc = Rc::new(arg.to_owned());
        let output = if let Some(cached) = self.args_format_cache.get(&argrc) {
            // load from cache
            Rc::clone(&cached)
        } else if let Some(slash_index) = arg.find("/") {
            // only work on stuff that is probably a path. I do not verify paths
            // because I want this to work on most file-like stuff and whatnot
            let (left, right) = arg.split_at(slash_index);
            // The left string has no slashes and is probably not a path.
            // Call this function recursively so it gets styled like a normal nonpathlike string
            let left = self.get_styled_arg(left);
            let right_rc = Rc::new(right.to_owned());

            let styled_path = if let Some(right_string) = self.args_format_cache.get(&right_rc) {
                // the right string can be in the cache separately too
                Rc::clone(&right_string)
            } else {
                let right_style = self.ls_colors.style_for_path_components(Path::new(right));
                let right_vec = right_style
                    .map(|(str, style_opt)| {
                        let segment = str.to_string_lossy();
                        if let Some(style) = style_opt {
                            style.to_nu_ansi_term_style().paint(segment).to_string()
                        } else {
                            // fallback to the default args style
                            style_args_default!(segment, norc)
                        }
                    })
                    .collect::<Vec<String>>();
                // collect the result path stuff into a string
                let right_result = Rc::new(right_vec.join(""));

                // put formatted path into cache for easier computation and whatnot
                self.args_format_cache
                    .insert(Rc::clone(&right_rc), Rc::clone(&right_result));

                Rc::clone(&right_result)
            };

            let stylestr = Rc::new(format!("{}{}", left, styled_path));
            // This line inserts the entire thing into the cache, but the left one is treated like a normal arg so there's literally no need.
            // self.args_format_cache
            //     .insert(Rc::clone(&argrc), Rc::clone(&stylestr));
            stylestr
        } else {
            // fallback to the default args style
            let styled = style_args_default!(arg);
            self.args_format_cache
                .insert(Rc::clone(&argrc), Rc::clone(&styled));
            styled
        };
        unrc!(output)
    }
    /// This is literally just here so I can cache duplicate names. It is not designed to be convenient to use in other contexts.
    pub fn get_styled_name(
        &mut self,
        name: &str,
        process_state: procinfo::RecognizedStates,
    ) -> String {
        // Show if the process is dead
        if process_state == procinfo::RecognizedStates::Unknown
            || process_state == procinfo::RecognizedStates::Zombie
        {
            return process_state
                .to_nu_ansi_term_style()
                .paint(name)
                .to_string();
        }

        // process is alive and well
        let namerc = Rc::new(name.to_owned());
        let result_rc = if let Some(styled) = self.name_format_cache.get(&namerc) {
            // load from cache
            Rc::clone(&styled)
        } else {
            let styled_name = process_state
                .to_nu_ansi_term_style()
                .paint(name)
                .to_string();
            let styled_name_rc = Rc::new(styled_name);
            self.name_format_cache
                .insert(Rc::clone(&namerc), Rc::clone(&styled_name_rc));
            styled_name_rc
        };
        unrc!(result_rc)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Proc {
    pub name: String,
    pub state: procinfo::RecognizedStates,
    // pub user: procinfo::User,
    pub user_fmt: String,
    pub pid: i32,
    pub pid_styled: String,
    pub ppid: i32,
    pub args: Vec<String>,
    pub styled_args: Vec<String>,
}
impl Default for Proc {
    fn default() -> Self {
        Self {
            name: "".to_owned(),
            state: procinfo::RecognizedStates::Unknown,
            // user: procinfo::User::default(),
            user_fmt: "".to_owned(),
            pid: -1,
            pid_styled: "".to_owned(),
            ppid: -1,
            args: Vec::new(),
            styled_args: Vec::new(),
        }
    }
}
impl Proc {
    /// Basically the main function lmao. It takes so many args because it is supposed to be used in one specific way.
    pub fn from_procfs_proc(
        procfs_process: procfs::process::Process,
        user: Rc<procinfo::User>,
        style_cache: &mut StyleCache,
        approximate_preferred_width: usize,
    ) -> Result<Proc, procinfo::ProcError> {
        let filter_type = user.filter_type;

        let my_pid = procfs_process.pid();
        let pid_string = my_pid.to_string();

        let (parent_pid, name, state) = if let Ok(status) = procfs_process.status() {
            let stat_state = status.state.as_str();
            let my_state = stat_state.split_at(stat_state.find(" ").unwrap_or(1)).0;
            let my_state_recognized = procinfo::RecognizedStates::from(my_state);

            let my_styled_name = style_cache.get_styled_name(&status.name, my_state_recognized);
            (status.ppid, my_styled_name, my_state_recognized)
        } else {
            (-1, "".to_owned(), procinfo::RecognizedStates::Unknown)
        };

        let args = procfs_process.cmdline().unwrap_or_default();
        // Style the pid here because there's literally no way it could be cached.
        let (style_pid, styled_args) = if state == procinfo::RecognizedStates::Zombie {
            // if it's a zombie process, style with state
            (
                state
                    .to_nu_ansi_term_style()
                    .bold()
                    .paint(&pid_string)
                    .to_string(),
                vec![state
                    .to_nu_ansi_term_style()
                    .paint("<defunct/zombie>")
                    .to_string()],
            )
        } else {
            let pid_style = if state == procinfo::RecognizedStates::Unknown {
                state
                    .to_nu_ansi_term_style()
                    .bold()
                    .paint(&pid_string)
                    .to_string()
            } else {
                filter_type
                    .to_nu_ansi_term_style()
                    .paint(&pid_string)
                    .to_string()
            };

            let mut mutable_args = args.clone();

            // This makes it so the path to the binary is always first.
            // If it is a different string though, then still show it so that I still see the information.
            if let Some(first) = mutable_args.first() {
                if let Ok(binary) = procfs_process.exe() {
                    let binary_string = binary.to_string_lossy().to_string();
                    if first != &binary_string {
                        mutable_args[0] = format!("({})", first);
                        mutable_args.insert(0, binary_string);
                    }
                }
            }

            if mutable_args.is_empty() {
                mutable_args.push("(-)".to_owned()); // to make it look a bit more like linux ps
            }

            // Some electron apps and browsers have all the args as one giant arg. This is a hacky way to fix that.
            // If a filepath is unfortunate enough to have a space in it, then it will be split, but its parent dir might still be styled.
            let args_iter = mutable_args.iter().flat_map(|a| a.split(" "));

            let args_style = args_iter
                .map(|a| style_cache.get_styled_arg(a))
                .collect::<Vec<String>>();

            // let mut args_style = Vec::new();
            // // I am styling these all here just so there is less duplicated work and computation. I don't need the bare args.
            // // Make sure I don't overflow the terminal with tons of args if I don't have to.
            // let mut line_length = 0;
            // for arg in args_iter {
            //     if line_length < approximate_preferred_width {
            //         // arg.chars.count() is a O(n) operation, but it works on unicode.
            //         let arg_length = arg.chars().count();
            //         args_style.push(style_cache.get_styled_arg(arg));
            //         line_length = line_length + arg_length;
            //     }
            // }
            (pid_style, args_style)
        };

        Ok(Self {
            name,
            state,
            // user: unrc!(user),
            user_fmt: user.paint(),
            pid: my_pid,
            pid_styled: style_pid,
            ppid: parent_pid,
            args,
            styled_args,
        })
    }
    pub fn console_style(&self) -> String {
        let args_string = self.styled_args.join(" ");
        format!(
            "{}{}{}{}{}",
            self.pid_styled,
            style::DELIM,
            self.name,
            style::DELIM,
            args_string
        )
    }
    pub fn info_style(&self) -> String {
        format!(
            "PID: {}, NAME: {}, STATE: {}
USER: {}
ARGS: {}",
            self.pid_styled,
            self.name,
            self.state.paint(),
            // self.user.paint(),
            self.user_fmt,
            self.styled_args.join(" ")
        )
    }
    pub fn from_pid(pid: i32) -> Result<Self, procinfo::ProcError> {
        let procfs_process = procfs::process::Process::new(pid)?;
        let user = if let Some(u) = procinfo::User::from_uid(procfs_process.uid()?) {
            Rc::new(u)
        } else {
            return Err(procinfo::ProcError::CustomError(
                "Could not find user!".to_owned(),
            ));
        };

        let mut style_cache = StyleCache::default();

        Self::from_procfs_proc(procfs_process, user, &mut style_cache, 0)
    }
}

use std::{
    collections::HashMap,
    env,
    fs::DirEntry,
    io,
    path::{self, Path, PathBuf},
    process,
};
use zsh_module::{zsh, Builtin, MaybeError, Module, ModuleBuilder, Opts};

const MAX_TIMER_TIMEOUT: usize = 15;
zsh_module::export_module!(testmod, setup);

#[derive(Debug, Clone, Copy)]
struct Timer {
    last_seconds: usize,
    seconds: usize,
    minutes: usize,
    hours: usize,
}
impl Default for Timer {
    fn default() -> Self {
        Self {
            last_seconds: 0,
            seconds: 0,
            minutes: 0,
            hours: 0,
        }
    }
}
impl Timer {
    fn start(&mut self, last_seconds: usize) {
        self.last_seconds = last_seconds;
        self.seconds = 0;
        self.minutes = 0;
        self.hours = 0;
    }
    fn calculate(&mut self, current_seconds: usize) {
        self.hours = current_seconds / 3600;
        self.minutes = (current_seconds % 3600) / 60;
        self.seconds = current_seconds % 60;
    }
}

#[derive(Debug, Clone)]
struct ShellState {
    // formatting helper
    emptystr: String,
    empty_pathbuf: PathBuf,

    // cwd function
    has_git_command: bool,
    git_state: bool,
    git_repo: String,

    last_cwd: PathBuf,
    current_cwd: PathBuf,

    cwd_writable: bool,
    cwd_is_link: bool,
    // so I can have ~bin and whatnot
    nameddirs: HashMap<String, PathBuf>,

    timer: Timer,

    has_sudo_command: bool,
    sudo_state: bool,

    venv_path: String,
    venv_state: bool,
}

impl ShellState {
    fn new() -> Result<Self, io::Error> {
        let empty_pathbuf = PathBuf::new();
        let emptystr = "".to_string();

        // check if we have required commands
        let mut has_git = false;
        let mut has_sudo = false;
        let env_path = env::var("PATH").unwrap_or("/usr/local/bin:/usr/bin:/bin".to_string());

        for i in env_path
            .split(":")
            .filter_map(|i| Path::new(i).read_dir().ok())
            .flatten()
            .filter_map(|i| i.ok())
            .map(|i| i.file_name())
        // .map(|i| i.file_name().to_string_lossy().to_string())
        {
            let fucking_osstr_bullshit = i.to_str().unwrap_or_default();
            if fucking_osstr_bullshit.ends_with("/git") {
                has_git = true;
            } else if fucking_osstr_bullshit.ends_with("/sudo") {
                has_sudo = true;
            }
            if has_git && has_sudo {
                break;
            }
        }
        has_sudo = has_sudo && env::var("DISTROBOX_ENTER_PATH").is_err();

        let mut mystate = ShellState {
            emptystr: emptystr.clone(),
            empty_pathbuf: empty_pathbuf.clone(),
            has_git_command: has_git,
            git_state: false,
            git_repo: emptystr.clone(),
            cwd_writable: false,
            cwd_is_link: false,
            last_cwd: empty_pathbuf.clone(),
            current_cwd: empty_pathbuf,
            nameddirs: HashMap::new(),
            timer: Timer::default(),
            has_sudo_command: has_sudo,
            sudo_state: false,
            venv_path: emptystr.clone(),
            venv_state: false,
        };
        mystate.refresh_dir_info()?;
        mystate.refresh_sudo();
        mystate.refresh_venv();

        // if let Err(nameddirs_err) = mystate.get_nameddirs() {
        //     eprintln!(
        //         "There was an error getting the named directories!, {:?}",
        //         nameddirs_err
        //     )
        // }

        Ok(mystate)
    }

    fn refresh_dir_info(&mut self) -> Result<(), io::Error> {
        let cwd = if let Ok(cwd_from_var) = env::var("PWD") {
            PathBuf::from(cwd_from_var)
        } else {
            eprintln!("Error getting PWD from env");
            env::current_dir().unwrap_or_default()
        };

        if cwd == self.last_cwd {
            return Ok(());
        } else {
            self.last_cwd = self.current_cwd.clone();
            self.current_cwd = cwd;
        }
        println!("dbug -- evaluation");
        if self.has_git_command {
            if let Ok(git_out) = process::Command::new("git")
                .args(["rev-parse", "--show-toplevel"])
                .output()
            {
                let gitrepo = String::from_utf8_lossy(&git_out.stdout).trim().to_owned();
                if let Some(slash_index) = gitrepo.rfind("/") {
                    self.git_repo = gitrepo.split_at(slash_index + 1).1.to_owned();
                } else {
                    self.git_repo = gitrepo
                }
                self.git_state = git_out.status.success();
            } else {
                self.git_repo = "".to_owned();
                self.git_state = false;
            }
        }
        self.cwd_is_link = self.current_cwd.is_symlink();
        if let Ok(current_cwd_metadata) = self.current_cwd.metadata() {
            self.cwd_writable = current_cwd_metadata.permissions().readonly();
        }
        Ok(())
    }

    fn refresh_sudo(&mut self) {
        if self.has_sudo_command {
            if let Ok(sudocmd) = process::Command::new("sudo").arg("-vn").output() {
                self.sudo_state = sudocmd.status.success()
            } else {
                self.sudo_state = false;
            }
        } else {
            self.sudo_state = false;
        }
    }

    fn refresh_venv(&mut self) {
        if let Ok(venv) = env::var("VIRTUAL_ENV") {
            if !venv.is_empty() {
                self.venv_state = true;
                self.venv_path = venv;
            } else {
                self.venv_state = false;
                self.venv_path = self.emptystr.clone();
            }
        } else {
            self.venv_state = false;
            self.venv_path = self.emptystr.clone();
        }
    }

    // fn get_nameddirs(&mut self) -> MaybeError {
    //     zsh::eval_simple("export __vlkprompt_internal_hashed_dir_keys=\"${(@kj.:.)nameddirs}\" __vlkprompt_internal_hashed_dir_values=\"${(@vj.:.)nameddirs}\"")?;
    //     // try to get the values
    //     let namedir_keys_str =
    //         env::var("__vlkprompt_internal_hashed_dir_keys").unwrap_or(self.emptystr.clone());
    //     let nameddir_vals_str =
    //         env::var("__vlkprompt_internal_hashed_dir_values").unwrap_or(self.emptystr.clone());

    //     let mut nameddir_keys = namedir_keys_str.split(":");
    //     let mut nameddir_vals = nameddir_vals_str.split(":");

    //     loop {
    //         // if both are valid, insert. If both are invalid, it's over. Both should be either valid or invalid.
    //         // If one is valid and the other isn't, then an error occured and the loop exits to prevent UB
    //         if let Some(key) = nameddir_keys.next() {
    //             if let Some(value) = nameddir_vals.next() {
    //                 let pathbuf_val = PathBuf::from(value);
    //                 if pathbuf_val.exists() {
    //                     // only insert if it exists!
    //                     self.nameddirs.insert(key.to_owned(), pathbuf_val);
    //                 }
    //                 continue;
    //             };
    //         }
    //         break;
    //     }
    //     Ok(())
    // }

    fn precmd_hook(&mut self, _name: &str, _args: &[&str], _opts: Opts) -> MaybeError {
        self.timer.start(env::var("SECONDS")?.parse()?);
        Ok(())
    }

    fn prompt_initialize(&mut self, _name: &str, _args: &[&str], _opts: Opts) -> MaybeError {
        zsh::eval_simple("precmd_functions+=('ShellState::promptcmd'); chpwd_functions+=('ShellState::chpwd_cmd')")?;
        Ok(())
    }

    fn promptcmd(&mut self, _name: &str, _args: &[&str], _opts: Opts) -> MaybeError {
        // self.refresh_dir_info()?;
        self.refresh_sudo();
        self.print_fmt();
        Ok(())
    }

    fn chpwd_cmd(&mut self, _name: &str, _args: &[&str], _opts: Opts) -> MaybeError {
        self.refresh_dir_info()?;
        Ok(())
    }

    fn print_fmt(&self) {
        println!("ShellState Object Dump\n\n{:#?}", &self);
    }
}

fn setup() -> Result<Module, Box<dyn std::error::Error>> {
    if let Ok(shellstate) = ShellState::new() {
        let module = ModuleBuilder::new(shellstate)
            .builtin(
                ShellState::prompt_initialize,
                Builtin::new("ShellState::prompt_initialize"),
            )
            .builtin(
                ShellState::precmd_hook,
                Builtin::new("ShellState::precmd_hook"),
            )
            .builtin(ShellState::promptcmd, Builtin::new("ShellState::promptcmd"))
            .builtin(ShellState::chpwd_cmd, Builtin::new("ShellState::chpwd_cmd"))
            .build();

        Ok(module)
    } else {
        println!("Could not derive shell state!");
        todo!()
    }
}

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn it_works() {
//         let result = add(2, 2);
//         assert_eq!(result, 4);
//     }
// }

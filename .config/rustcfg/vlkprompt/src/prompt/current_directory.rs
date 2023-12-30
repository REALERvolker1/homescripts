use crate::{config, configlib, format, prompt};
use git2;
use std::{
    env, mem,
    path::{Path, PathBuf},
};

pub const CURRENT_DIRECTORY: &str = "current_directory";

/// An enum to define what kind of color/icons to show in the prompt
#[derive(PartialEq, Debug, Clone, Default)]
pub enum CwdState {
    // Vim, // I plan on adding a different prompt segment for this
    Home,
    Git(String),
    Symlink,
    #[default]
    Regular,
}
impl CwdState {
    pub fn for_dir(dir: &Path, git_ceilings: &[&Path]) -> Self {
        // chances are, you probably don't want to see home as a git dir
        // if you are using a git bare repo for your dotfiles or something
        if let Ok(home) = env::var("HOME") {
            if dir.to_string_lossy() == home {
                return Self::Home;
            }
        }

        // A naive implementation of `git rev-parse --show-toplevel`
        if let Ok(repo_root) = git2::Repository::discover_path(dir, git_ceilings) {
            if let Some(p) = repo_root.parent() {
                if let Some(n) = p.file_name() {
                    return Self::Git(n.to_string_lossy().to_string());
                }
            }
        }

        if dir.is_symlink() {
            return Self::Symlink;
        }

        return Self::Regular;

        // Keeping this open to add room for more options later
    }
}

#[derive(Debug, Clone, Default)]
pub struct Cwd {
    pub cwd: PathBuf,
    pub state: CwdState,
    pub is_writable: bool,
    /// if it is a zsh hashed directory from `hash -d`
    pub is_hashed_dir: bool,
}
impl prompt::DynamicModule for Cwd {
    /// The update type is supposed to be Path
    fn update(&mut self, update_type: prompt::UpdateType) -> prompt::UpdateResult<()> {
        if let prompt::UpdateType::Path(cwd) = update_type {
            self.cwd = cwd;
            prompt::UpdateResult::Ok(())
        } else {
            // panic!("Cwd module only supports UpdateType::Path");
            prompt::UpdateResult::Err(prompt::UpdateError::UpdateTypeError(update_type))
        }
    }
}
impl prompt::Module for Cwd {
    fn should_show(&self) -> bool {
        true
    }
    fn format(&self) -> format::Format {
        match self.state {
            CwdState::Home => config::FMT_CONFIG.cwd.home,
            CwdState::Git(_) => config::FMT_CONFIG.git,
            CwdState::Symlink => {
                if self.is_writable {
                    config::FMT_CONFIG.cwd.lnk
                } else {
                    config::FMT_CONFIG.cwd.lnk_ro
                }
            }
            CwdState::Regular => {
                if self.is_writable {
                    config::FMT_CONFIG.cwd.reg
                } else {
                    config::FMT_CONFIG.cwd.reg_ro
                }
            }
        }
    }
}

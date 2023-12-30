use crate::{
    constants::{self, FormatSource},
    Stateful,
};
use git2;
use std::{
    env, mem,
    path::{Path, PathBuf},
};
use zsh_module;

/// An enum to define what kind of color/icons to show in the prompt
#[derive(PartialEq, Debug, Clone, Default)]
pub enum CwdState {
    Vim,
    Git(String),
    Symlink,
    #[default]
    Regular,
}

#[derive(Debug, Clone, Default)]
pub struct Cwd {
    pub cwd: PathBuf,
    /// Internal variable used to keep track of vi mode stuff
    old_state: CwdState,
    pub state: CwdState,
    pub is_writable: bool,
}
impl FormatSource for Cwd {
    fn format(&self) -> constants::Format {
        match self.state {
            CwdState::Git(_) => constants::FMT_CONFIG.cwd.git,
            CwdState::Vim => constants::FMT_CONFIG.cwd.vim,
            CwdState::Symlink => {
                if self.is_writable {
                    constants::FMT_CONFIG.cwd.lnk
                } else {
                    constants::FMT_CONFIG.cwd.lnk_ro
                }
            }
            CwdState::Regular => {
                if self.is_writable {
                    constants::FMT_CONFIG.cwd.reg
                } else {
                    constants::FMT_CONFIG.cwd.reg_ro
                }
            }
        }
    }
}
impl Stateful for Cwd {
    fn update(&mut self) {
        // just use the last cached values
        let cwd = if let Ok(d) = env::current_dir() {
            if d == self.cwd {
                return;
            } else {
                d
            }
        } else {
            return;
        };

        // update it
        self.cwd = cwd;
        self.state = self.compute_state();
    }
}
impl Cwd {
    pub fn compute_state(&self) -> CwdState {
        let cwd_path = self.cwd.as_path();

        // A naive implementation of `git rev-parse --show-toplevel`
        if let Ok(repo_root) =
            git2::Repository::discover_path(cwd_path, constants::GIT_CEILING_DIRS.iter())
        {
            if let Some(p) = repo_root.parent() {
                if let Some(n) = p.file_name() {
                    return CwdState::Git(n.to_string_lossy().to_string());
                }
            }
        }

        if cwd_path.is_symlink() {
            return CwdState::Symlink;
        }

        return CwdState::default();
    }

    /// For vim mode prompt thingy
    pub fn set_viins(&mut self, is_vi_normal: bool) {
        if is_vi_normal {
            // Get what state we should be in rn if for some reason it was toggled on twice or whatever
            if self.old_state == CwdState::Vim {
                self.old_state = self.compute_state();
            }
            mem::swap(&mut self.old_state, &mut self.state);
        } else {
            self.old_state = mem::replace(&mut self.state, CwdState::Vim);
        }
    }
}

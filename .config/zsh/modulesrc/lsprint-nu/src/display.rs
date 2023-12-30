use crate::constants::*;
use lscolors::Style;
use std::{
    collections::{self, HashMap},
    env, ffi, io, os,
    path::{Path, PathBuf},
};
use zsh_module;
use zsh_sys;

/// The main global mutable state of the module
#[derive(Debug, Clone)]
pub struct State {
    cwd: PathBuf,
    git: bool,
    files: Vec<FmtFile>,
    count: usize,
}
impl Default for State {
    fn default() -> Self {
        Self {
            cwd: env::current_dir().unwrap(),
            git: false,
            files: vec![],
            count: 0,
        }
    }
}
impl State {
    pub fn counter(
        &mut self,
        _name: &str,
        _args: &[&str],
        _opts: zsh_module::Opts,
    ) -> zsh_module::MaybeError {
        self.count += 1;
        zsh_module::zsh::eval_simple(&format!("ZSH_MODULE_COUNTER={}", self.count))?;
        println!("{}", self.count);
        Ok(())
    }
    pub fn setalias(
        &mut self,
        _name: &str,
        args: &[&str],
        opts: zsh_module::Opts,
    ) -> zsh_module::MaybeError {
        let current_opts = opts;
        let mut args_iter = args.iter();

        // while let Some(alias_name) = args_iter.next() {
        //     if let Some(alias_str) = args_iter.next() {
        //         alias_map.insert(alias_name, alias_str);
        //     } else {
        //         // zsh_module::error!("expected an alias value");
        //         return Err("expected an alias value".into());
        //     };
        // }
        // args.

        let (aliases, remainder) = args.as_chunks::<2>();
        if remainder.len() > 0 {
            zsh_module::error!("expected an alias value");
            return Err("expected an alias value".into());
        }
        // let alias_map = aliases
        //     .iter()
        //     .map(|a| (a[0], a[1]))
        //     .collect::<HashMap<_, _>>();

        for (alias_name_str, alias_cmd_str) in aliases.iter().map(|a| (a[0], a[1])) {
            unsafe {
                let alias_name = ffi::CString::new(alias_name_str)?;
                let alias_cmd = ffi::CString::new(alias_cmd_str)?;

                let alias_name_ptr = alias_name.as_ptr();

                zsh_sys::bin_alias(alias_names, argv, ops, func)
                // zsh_module::zsh::eval_simple(&format!("alias {}={}", alias_name, alias_str))?;
            }
        }

        // let current_opts = zsh_module::Opts::from(vec![]);
        // // zsh_module::zsh::eval_simple(&format!("ZSH_MODULE_HASH={}", zsh_module::hash()))?;
        // let alias_name = ffi::CString::new(name)?;
        // let alias_ptr = alias_name.as_ptr();
        // let hashtable = zsh_sys::bin_alias(alias_ptr, argv, ops, func)
        Ok(())
    }
}

/// List the contents of a directory, returning format strings
///
/// TODO: only format the ones that would fit in the terminal
fn ls(directory: &Path) -> Result<Vec<FmtFile>, io::Error> {
    let files = directory
        .read_dir()?
        .filter_map(|e| e.ok())
        .filter_map(|e| FmtFile::from_path(e.path().as_path()))
        .collect::<Vec<_>>();
    Ok(files)
}

#[derive(Debug, Clone)]
pub struct FmtFile {
    pub name: String,
    pub length: usize,
    pub style: Style,
    pub is_dir: bool,
}
impl FmtFile {
    pub fn from_str(some_path: &str) -> Self {
        if let Some(p) = Self::from_path(Path::new(some_path)) {
            p
        } else {
            Self {
                name: some_path.to_owned(),
                length: some_path.chars().count(),
                style: Style::default(),
                is_dir: false,
            }
        }
    }
    pub fn from_path(path: &Path) -> Option<Self> {
        let name = path.file_name()?.to_string_lossy().to_string();

        let length = name.chars().count();

        let style = if let Some(s) = LS_COLORS.style_for_path(path) {
            s.to_owned()
        } else {
            Style::default()
        };

        let is_dir = path.is_dir();

        Some(Self {
            name,
            length,
            style,
            is_dir,
        })
    }
}

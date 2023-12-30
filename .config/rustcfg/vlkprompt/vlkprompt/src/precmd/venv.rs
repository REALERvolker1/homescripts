///! This module is meant to provide stuff for conda, python venv, and nix env.
use std::{
    env,
    path::{Path, PathBuf},
};

#[derive(Debug, Clone)]
pub struct EnvVar {
    pub varname: String,
    pub current_value: String,
    pub is_set: bool,
}
impl EnvVar {
    pub fn new(varname: String) -> Self {
        Self {
            varname,
            current_value,
            is_set,
        }
    }
    pub fn update
}

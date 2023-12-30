///! This module is meant to provide stuff for conda, python venv, and nix env. Basically shell environments.
use crate::{config, configlib, format, prompt};
use std::{
    env,
    path::{Path, PathBuf},
};

/// The type of module this happens to be
#[derive(Debug, Clone, Copy)]
pub enum EnvType {
    /// Anaconda
    Conda,
    /// python venv
    Python,
    /// the nix shell type, `$IN_NIX_SHELL`
    Nix,
}
impl EnvType {
    pub fn from_varname(varname: &str) -> Self {
        match varname {
            "CONDA_DEFAULT_ENV" => Self::Conda,
            "VIRTUAL_ENV" => Self::Python,
            "IN_NIX_SHELL" => Self::Nix,
            _ => unimplemented!("{} is not currently implemented!", varname),
        }
    }
    fn get_formatting(&self) -> format::Format {
        match self {
            Self::Conda => config::FMT_CONFIG.conda,
            Self::Python => config::FMT_CONFIG.venv,
            Self::Nix => config::FMT_CONFIG.nix,
        }
    }
}

/// A prompt segment that represents an environment variable
#[derive(Debug, Clone)]
pub struct EnvModule {
    pub variable: configlib::EnvVar,
    /// The actual functional module body
    pub env_type: EnvType,
}
impl EnvModule {
    pub fn new(varname: &str) -> Self {
        let env_type = EnvType::from_varname(varname);
        let variable = configlib::EnvVar::new(varname);

        Self { variable, env_type }
    }
}
impl prompt::DynamicModule for EnvModule {
    fn update(&mut self, update_type: prompt::UpdateType) -> prompt::UpdateResult<()> {
        self.variable.refresh();
        prompt::UpdateResult::Ok(())
    }
}
impl prompt::Module for EnvModule {
    fn format(&self) -> format::Format {
        self.env_type.get_formatting()
    }
    fn should_show(&self) -> bool {
        self.variable.value.is_some()
    }
}

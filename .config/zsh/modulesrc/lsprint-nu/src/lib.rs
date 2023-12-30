#![feature(slice_as_chunks)]

use crossterm;
use std::{
    env, error,
    path::{Path, PathBuf},
};
use zsh_module;

zsh_module::export_module!(lsprint, setup);

pub mod constants;
pub mod display;

fn setup() -> Result<zsh_module::Module, Box<dyn error::Error>> {
    let module = zsh_module::ModuleBuilder::new(display::State::default())
        .builtin(display::State::counter, zsh_module::Builtin::new("counter"))
        .build();
    Ok(module)
}

use lscolors;
use std::{env, io, path::*};
use unicode_width;
mod error;
mod grid;
mod utils;
mod argparse;

fn main() -> Result<(), error::TuError> {
    println!("Hello, world!");
    let props = utils::TermProps::new();
    // let cwd = env::current_dir()?;
    let cwd = Path::new("/bin");

    let ls_colors = lscolors::LsColors::from_env().unwrap_or_default();

    let grid = grid::ls_grid(&props, &cwd, &ls_colors)?;
    println!("{}", grid);

    Ok(())
}

use lscolors;
use std::{
    env, error,
    path::{Path, PathBuf},
};

mod runtime;
mod types;

fn main() -> Result<(), Box<dyn error::Error>> {
    let args = env::args().skip(1).collect::<Vec<String>>();
    // runtime::ls_colors(args)?;
    let lscolor_files = runtime::argparse(args)?;
    let lscolor_main = runtime::ls_colors(lscolor_files);
    Ok(())
}

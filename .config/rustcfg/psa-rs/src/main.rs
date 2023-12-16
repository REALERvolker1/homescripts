use std::{
    env, io,
    path::{Path, PathBuf},
    rc,
};

mod procs;
// mod ui;

fn main() -> eyre::Result<()> {
    // ui::tui()?;
    let processes = procs::refresh()?;
    println!("{:#?}", processes);
    Ok(())
}

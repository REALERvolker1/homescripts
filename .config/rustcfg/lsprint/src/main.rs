mod constants;
mod ls;
mod render;

use crossterm;
use lscolors;
use std::{env, fs::DirEntry, io, path::Path};

fn main() -> io::Result<()> {
    // determine if I should render this at all
    let (x_max, y_max) = crossterm::terminal::size()?;
    if y_max < constants::MIN_WINDOW_HEIGHT {
        // print here for debugging purposes. Remove for production
        eprintln!(
            "Not enough space to render! {} < {}",
            y_max,
            constants::MIN_WINDOW_HEIGHT
        );
        return Ok(());
    }

    // get path to render
    let renderpath = if let Some(path_string) = env::args().skip(1).next() {
        let path = Path::new(&path_string).to_path_buf();
        if path.is_dir() {
            path
        } else {
            env::current_dir()?
        }
    } else {
        env::current_dir()?
    };

    let ls_colors = lscolors::LsColors::from_env().unwrap_or_default();
    // let files = ls::get_dir_files(&cwd)?;
    let dir = renderpath
        .read_dir()?
        .into_iter()
        .filter_map(|f| f.ok())
        .collect::<Vec<DirEntry>>();

    // return if there are no files
    if dir.is_empty() {
        // print here for debugging purposes. Remove for production
        eprintln!("No files found in {}", renderpath.display());
        return Ok(());
    }

    render::render(x_max, y_max, &dir, &ls_colors)?;

    println!("Done with main");
    Ok(())
}

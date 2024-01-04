use lscolors;
use std::{env, rc::Rc};
mod bruh;
mod constants;
mod format;

/// I thought this program would be cool and easy to write, but it's ugly asf, I'm so sorry
///
/// The API sucks, it's disorganized, etc. I only really finished it because I was like 90% done with my prototype anyways
fn main() -> Result<(), bruh::PrintError> {
    let cwd = env::current_dir()?;
    let mut options = bruh::Options::from_args()?;

    let ls_colors = lscolors::LsColors::from_env().unwrap_or_default();
    let default_style = lscolors::Style::default();

    let hashed_dirs = if options.read_stdin {
        bruh::HashedDirectory::from_stdin()?
    } else {
        bruh::HashedDirectory::only_home()
    };

    while let Some(dir_content) = options.dirs_next(&ls_colors, &default_style) {
        let content = dir_content.table_format();

        let window = format::format_window(
            &content,
            dir_content.width,
            dir_content.surplus,
            &cwd,
            &hashed_dirs,
        );
        println!("{}", &window);

        // I'm feeling supeer lazy
        // let display_width = display_contents.first().unwrap().chars().count() - 2;
    }

    Ok(())
}

// fn list_dir(options: &mut bruh::Options) -> Result<(), bruh::PrintError> {

//     Ok(())
// }

// fn termsize()

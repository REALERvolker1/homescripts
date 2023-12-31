use lscolors;
use std::rc::Rc;
mod bruh;
mod constants;
mod format;

fn main() -> Result<(), bruh::PrintError> {
    let mut options = bruh::Options::from_args()?;

    let ls_colors = lscolors::LsColors::from_env().unwrap_or_default();
    let default_style = lscolors::Style::default();

    while let Some(dir_content) = options.dirs_next(&ls_colors, &default_style) {
        let content = dir_content.table_format();

        // I'm feeling supeer lazy
        // let display_width = display_contents.first().unwrap().chars().count() - 2;

        println!("{}", &content);
    }

    Ok(())
}

// fn list_dir(options: &mut bruh::Options) -> Result<(), bruh::PrintError> {

//     Ok(())
// }

// fn termsize()

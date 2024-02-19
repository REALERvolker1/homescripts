mod action;
mod config;
mod format;
mod prelude;

use config::{InteractiveType, PromptInput};
use prelude::*;

fn main() -> Res<()> {
    simple_eyre::install()?;
    let conf = config::Args::new()?;
    let ls_colors = if conf.is_colored {
        Some(lscolors::LsColors::from_env().unwrap_or_default())
    } else {
        None
    };

    // loads the lazy static before I do all kinds of parsing that could be unnecessary
    if conf.ignore_me_recursive {
        eprintln!("Ignoring recursive flag");
    }

    let format_paths = conf
        .sendable_paths
        .iter()
        .filter_map(|p| {
            match FormattedPath::new(
                p,
                conf.prompt == config::PromptType::Verbose,
                ls_colors.as_ref(),
            ) {
                Ok(p) => Some(p),
                Err(e) => {
                    eprintln!("{}", e);
                    None
                }
            }
        })
        .filter_map(|formatted_path| {
            // I set the action type to skip earlier, this makes it choose my preferred action type
            match conf.interactive {
                InteractiveType::Never => Some(formatted_path.set_action(conf.action)),
                // I check this condition later
                InteractiveType::Once => Some(formatted_path),
                InteractiveType::Always => {
                    match conf.prompt.prompt(PromptInput::Always(formatted_path)) {
                        Ok(modded_input) => Some(modded_input.unwrap_always()),
                        Err(e) => {
                            eprintln!("{e}");
                            None
                        }
                    }
                }
            }
        })
        .collect::<Vec<_>>();

    let paths = if conf.interactive == InteractiveType::Once {
        conf.prompt
            .prompt(PromptInput::Once(format_paths))?
            .unwrap_once()
    } else {
        format_paths
    };

    action::act(paths)?;

    Ok(())
}

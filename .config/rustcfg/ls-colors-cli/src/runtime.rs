use crate::types::File;
use lscolors;
use std::{
    env, io,
    path::{Path, PathBuf},
};

pub fn argparse(args: Vec<String>) -> io::Result<Vec<File>> {
    // disable argparsing, just add to files vec
    let mut disable_optparse = false;
    // files to color
    let mut file_args = Vec::new();

    let mut used_file = File::default();

    if args.is_empty() {
        let stdin_lines = io::stdin().lines().filter_map(|ln| ln.ok());
        for line in stdin_lines {
            used_file.file = line;
            file_args.push(used_file.clone());
        }
    } else {
        for arg in args {
            // pulled out of argparse code because it has to work even if we aren't parsing args
            let file_from_stdin = &arg == "-";

            // skip options parsing if we don't have to
            if !disable_optparse
                && !file_from_stdin
                && (arg.starts_with("-") || arg.starts_with("+"))
            {
                // decidedly not a file
                match arg.to_ascii_lowercase().as_str() {
                    "--recursive" | "-r" => used_file.recursive = true,
                    "--no-recursive" | "+r" => used_file.recursive = false,
                    "--error" | "-e" => used_file.error = true,
                    "--no-error" | "+e" => used_file.error = false,
                    "--color" | "-c" => used_file.ansi_only = true,
                    "--filepath" | "+c" => used_file.ansi_only = false,
                    "--" => disable_optparse = true,
                    _ => panic!(
                        "Invalid option received: `{}`
Available options:

Recursive mode:
Recursively color each directory, every 'segment' of the file
If disabled, print the entire filepath only colorized with the file's own color
- This helps identify symlinks

--recursive (-r)        Enable recursive
--no-recursive (+r)     Disable recursive

Error mode:
Print an error message to STDERR if a filepath does not exist
Otherwise, disable errors, making the best attempt at colorizing the path
- If disabled, temporarily enables recursive mode

--error   (-e)      Enable errors
--no-error (+e)     Disable errors

Output mode (ansi_only):
Only print the ANSI color string (ansi_only) that the filepath would have been colored with
Otherwise, print the full filepath colorized.
- If enabled, temporarily disables recursive

--color (-c)        enable Ansi-only output
--filepath (+c)     Disable Ansi-only output

Other:

-       Read a line from STDIN and insert it into the list at this position

--      Disable argument parsing for the rest of the args, useful when a file starts with '-'

Default config: {:#?}
",
                        &arg,
                        File::default()
                    ),
                }
            } else {
                used_file.file = if file_from_stdin {
                    let mut linebuf = String::new();
                    io::stdin().read_line(&mut linebuf)?;
                    linebuf.trim().to_owned()
                } else {
                    arg
                };
                // probably a file
                file_args.push(used_file.clone());
            }
        }
    }
    Ok(file_args)
}

pub fn ls_colors(files: Vec<File>) -> io::Result<()> {
    let ls_colors = lscolors::LsColors::from_env().unwrap_or_default();

    let mut stdout: Vec<String> = Vec::new();
    let mut stderr: Vec<String> = Vec::new();

    for file in files {
        let filepath = Path::new(&file.file);

        let filepath_exists = filepath.exists();
        if !filepath_exists && file.error {
            // stderrlock
            //     .write(format!("Error, path '{}' does not exist!\n", &file.file).as_bytes())?;
            stderr.push(format!("Error, path '{}' does not exist!\n", &file.file));
            continue;
        } else if file.file.is_empty() {
            stdout.push(String::new());
            continue;
        }

        // split here for readability, compiler should optimize
        let is_component_style =
            (file.recursive && !file.ansi_only) || (!filepath_exists && !file.error);

        let lscolored = if is_component_style {
            let mut colorpath: Vec<String> = Vec::new();
            let component_styles = ls_colors.style_for_path_components(filepath);

            for (segment, opt_style) in component_styles {
                // I hate OsString
                let segment_string = segment.to_string_lossy().to_string();

                if let Some(raw_style) = opt_style {
                    let style = raw_style.to_nu_ansi_term_style();
                    let stylestr = style.paint(segment_string);

                    colorpath.push(stylestr.to_string());
                } else {
                    colorpath.push(segment_string)
                }
            }
            colorpath.join("")
        } else {
            let paint_me = if file.ansi_only { "" } else { &file.file };

            if let Some(style) = ls_colors.style_for_path(filepath) {
                style.to_nu_ansi_term_style().paint(paint_me).to_string()
            } else {
                paint_me.to_owned()
            }
        };
        stdout.push(lscolored);
    }
    if !stderr.is_empty() {
        eprintln!("{}", stderr.join("\n"));
    }
    if !stdout.is_empty() {
        println!("{}", stdout.join("\n"));
    }
    Ok(())
}

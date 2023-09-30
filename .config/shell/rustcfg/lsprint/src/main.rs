use lscolors;
use nu_ansi_term;
use std::{cmp, env, error::Error, fmt::Display, path::PathBuf, process};

#[derive(Debug, Clone)]
struct Entry {
    pathbuf: PathBuf,
    file_name: String,
    is_dir: bool,
    fp_length: usize,
    disp_name: String,
}
// const DEFAULT_MAX_OUTPUT_LINES: usize = 6;

fn main() -> Result<(), Box<dyn Error>> {
    // can't have this displaying weirdly and whatnot
    let mut max_output_lines = 9999;
    let max_output_lines_var = env::var("LSPRINT_MAX_OUTPUT_LINES");
    if max_output_lines_var.is_ok() {
        let max_output_lines_i = max_output_lines_var.unwrap().parse::<usize>();
        if max_output_lines_i.is_ok() {
            max_output_lines = max_output_lines_i.unwrap()
        }
    }
    let stty_size = String::from_utf8(
        process::Command::new("stty")
            .args(["size", "-F", "/dev/stderr"])
            .stderr(process::Stdio::inherit())
            .output()?
            .stdout,
    )?;
    let mut stty_iter = stty_size.split_whitespace();
    let stty_height = stty_iter.next().unwrap().parse::<usize>()?;
    let stty_width = stty_iter.next().unwrap().parse::<usize>()?;
    let adjusted_height = stty_height - 2;
    let adjusted_width = stty_width - 2;

    if stty_height < max_output_lines {
        max_output_lines = (stty_height / 3) + 2;
    }
    if max_output_lines < 4 {
        // top + bottom of box drawing, plus 2 rows of output
        panic!("Terminal height is too small!")
    }
    if stty_width < 20 {
        // arbitrary magic number I made up on the spot
        panic!("Terminal width is too small!")
    }

    // get the file path contents
    let mut contents: Vec<Entry> = Vec::new();
    let mut column_size: usize = 0;
    let cwd = env::current_dir()?;
    for i_raw in cwd.read_dir()? {
        if i_raw.is_err() {
            continue;
        }
        // path
        let i = i_raw.unwrap().path();

        // length
        let i_moved_clone = i.clone();
        let mut i_name = i_moved_clone
            .file_name()
            .unwrap()
            .to_str()
            .unwrap()
            .to_string();
        let i_len = &i_name.chars().count() + 3; // add 2 to account for icon, 1 for a spacer
        if i_len > column_size {
            column_size = i_len
        }
        if i_len > adjusted_width {
            i_name.truncate(adjusted_width)
        }
        // fs operations take lots of time. If I can minimize this time, then that's pretty good.

        // icon
        let i_icon;
        let i_is_dir = i.is_dir();
        if i_is_dir {
            let i_readdir_raw = i.read_dir();
            if i.read_dir().is_ok() {
                if i_readdir_raw.unwrap().next().is_some() {
                    // directory has contents
                    i_icon = ""
                } else {
                    // empty directory
                    i_icon = ""
                }
            } else {
                // no perms for directory
                i_icon = ""
            }
            // i_icon = ""
        } else if i.is_file() {
            let file_metadata = i.metadata();
            if file_metadata.is_ok() {
                if file_metadata.unwrap().len() > 0 {
                    // file has contents
                    i_icon = ""
                } else {
                    // empty file
                    i_icon = ""
                }
            } else {
                // no perms for file
                i_icon = "󰩌"
            }
            // i_icon = ""󰩌
        } else if i.is_symlink() {
            // cannot find if file or dir, this is a fallback
            i_icon = ""
        } else {
            // if you see this things are def a little weird
            i_icon = "󱀶"
        }

        contents.push(Entry {
            pathbuf: i,
            disp_name: format!("{} {}", i_icon, &i_name),
            file_name: i_name,
            is_dir: i_is_dir,
            fp_length: i_len,
        });
    }
    let column_count = adjusted_width / column_size;
    // max_output_lines = contents.len() / column_count;
    // let full_size = column_count * max_output_lines;
    let full_size = max_output_lines * column_count;

    // sort hidden files first, and alphabetically
    contents.sort_by(|a, b| {
        if a.file_name.starts_with(".") && !b.file_name.starts_with(".") {
            cmp::Ordering::Less
        } else if !a.file_name.starts_with(".") && b.file_name.starts_with(".") {
            cmp::Ordering::Greater
        } else {
            a.file_name.cmp(&b.file_name)
        }
    });
    // group directories first
    contents.sort_by(|a, b| {
        if a.is_dir && !b.is_dir {
            cmp::Ordering::Less
        } else if !a.is_dir && b.is_dir {
            cmp::Ordering::Greater
        } else {
            cmp::Ordering::Equal
        }
    });
    let ls_colors = lscolors::LsColors::from_env().unwrap_or_default();
    // only take stuff we can print
    let mut string_contents = contents
        .iter()
        .take(full_size)
        .cloned()
        .map(|a| {
            (
                ls_colors
                    .style_for_path(&a.pathbuf)
                    .unwrap_or(ls_colors.style_for_path("/dev/null").unwrap())
                    .to_nu_ansi_term_style()
                    .paint(&a.disp_name)
                    .to_string(),
                a.fp_length,
            )
        })
        .collect::<Vec<(String, usize)>>();
    string_contents.resize(full_size, ("".to_string(), 0));

    let mut display = Vec::new();
    let mut count = 0;
    for (i, i_count) in string_contents {
        if count == 0 {
            display.push("│".to_string());
        }
        count += 1;
        let diff = column_size - i_count;
        display.push(format!("{}{:<diff$}", i, ""));
        if count == column_count {
            display.push("│".to_string());
            display.push("\n".to_string());
            count = 0;
        }
    }

    // let mut string_contents = printable_contents
    //     .iter()
    //     .map(|a| {
    //         let style = ls_colors
    //             .style_for_path(&a.pathbuf)
    //             .unwrap_or(ls_colors.style_for_path("/dev/null").unwrap())
    //             .to_nu_ansi_term_style();
    //         let diff = column_size - a.fp_length + 1;
    //         format!("{}{:<diff$}", style.paint(&a.disp_name).to_string(), "")
    //     })
    //     .collect::<Vec<String>>();

    // string_contents.resize(full_size, format!("{:<column_size$}", ""));

    // let mut display = Vec::new();
    // let mut count = 0;
    // for i in string_contents {
    //     if count == 0 {
    //         display.push("│".to_string());
    //     }
    //     count += 1;
    //     display.push(i);
    //     if count == column_count {
    //         display.push("│".to_string());
    //         display.push("\n".to_string());
    //         count = 0;
    //     }
    // }
    // if count != column_count {
    //     display.push("│".to_string())
    // }
    println!("{}", display.join(""));

    // style
    // let i_style = ls_colors
    //     .style_for_path(&i)
    //     .unwrap_or(ls_colors.style_for_path("/dev/null").unwrap());

    // println!("{}, {}", height, width);
    Ok(())
}

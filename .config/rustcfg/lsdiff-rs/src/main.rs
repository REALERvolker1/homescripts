// use eza;
// use lscolors;
// use nu_ansi_term::AnsiGenericString;
use std::{env, fs, io, path::Path, process};

enum Type {
    Symlink,
    Dir,
    File,
}

fn main() -> Result<(), io::Error> {
    let lsdiff_path_string = env::var("LSDIFF_PATH").unwrap_or(env::var("HOME").unwrap());
    let lsdiff_path = Path::new(&lsdiff_path_string);
    let cache_path_string = format!(
        "{}/lsdiff-rs.cache",
        &env::var("XDG_CACHE_HOME").unwrap_or(format!("{}/.cache", &env::var("HOME").unwrap()))
    );
    let cache_path = Path::new(&cache_path_string);

    let mut should_i_update_cache = false;
    if !cache_path.exists() {
        should_i_update_cache = true;
    } else if let Some(update_arg) = env::args().skip(1).next() {
        if update_arg.contains("--update") {
            should_i_update_cache = true;
        }
    }
    // let lscolors = lscolors::LsColors::from_env().unwrap_or_default();

    // let current_contents = lsdiff_path.read_dir()?.map(|i| {
    //     let i_path = i.unwrap().path();
    //     let i_type;
    //     if i_path.is_symlink()
    // });
    // let current_contents = lsdiff_path.read_dir()?;
    // let current_contents = eza::fs::Dir::read_dir(lsdiff_path.to_path_buf())?.files(
    //     eza::fs::DotFilter::DotfilesAndDots,
    //     None,
    //     false,
    //     true,
    // );
    // for i in current_contents {
    //     if i.is_err() {
    //         continue;
    //     }
    //     println!("{}", i.unwrap().)
    // }

    // env::set_current_dir(&lsdiff_path)?;
    // let file_cmd = process::Command::new("lsd")
    // .args([
    // "--ignore-config",
    // "-A1",
    // "--group-directories-first",
    // "--color=always",
    // "--icon=always",
    // ])
    // .output()?
    // .stdout;
    let file_cmd = process::Command::new("eza")
        .args([
            "-AX1",
            "--group-directories-first",
            "--icons=always",
            "--color=always",
        ])
        .output()?
        .stdout;

    let files_string = String::from_utf8_lossy(&file_cmd);

    let files = files_string.split("\n").collect::<Vec<&str>>();

    // println!("{}", files.join(",\n,"));

    if should_i_update_cache {
        println!("Updating cache");
        fs::write(&cache_path_string, files.join("\n"))?;
    }

    let cachefile_content = fs::read_to_string(&cache_path_string)?;
    let cachefiles = cachefile_content.split("\n").collect::<Vec<&str>>();

    // let mut files_check = Vec::new();
    // let mut old_contents = Vec::new();
    // let mut new_contents = Vec::new();
    for i in cachefiles.iter() {
        if !files.contains(&i) {
            println!("\x1b[1;91m-\x1b[0m {}", i);
            // old_contents.push(i.to_owned());
        }
    }
    for i in files.iter() {
        if !cachefiles.contains(&i) {
            println!("\x1b[1;92m+\x1b[0m {}", i);
            // new_contents.push(i.to_owned());
        }
    }
    // println!("old contents: {}", old_contents.join("\n"));
    // println!("new contents: {}", new_contents.join("\n"));

    Ok(())
}

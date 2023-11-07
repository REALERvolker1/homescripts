/*

vlk PATHMUNGE function
for making sure my $PATH is alright
also works on other PATHlike variables like $XDG_USER_DIRS, $MANPATH, etc
optimized for execution speed over memory usage.

*/
use std::{env, error, path::Path};

fn main() -> Result<(), Box<dyn error::Error>> {
    let path_owned = env::args()
        .skip(1)
        .map(|i| i.to_string())
        .collect::<Vec<String>>(); // making an entirely owned path from args to fight Rust borrow checker

    let mut path = path_owned.iter().map(|s| s.as_str()).collect::<Vec<&str>>(); // make it so we are dealing with just &str

    let path_env_string = env::var("PATHMUNGE_PATH").unwrap(); // despecify from PATH so we can munge other PATHlike variables
    let mut path_env = path_env_string.split(":").collect::<Vec<&str>>();

    path.append(&mut path_env); // throw into a single vec in order

    // let mut new_order = Vec::new(); // this is the variable we use for PATH
    let mut new_order = path
        .iter()
        .filter_map(|i| {
            let i_path = Path::new(i);
            if let Ok(mut i_read_dir) = i_path.read_dir() {
                if let Some(nxt) = i_read_dir.next() {
                    if let Ok(canonicalized) = i_path.canonicalize() {
                        Some(canonicalized.to_string_lossy().to_string())
                    } else {
                        None
                    }
                } else {
                    None
                }
            } else {
                None
            }
        })
        .collect::<Vec<String>>();

    new_order.dedup();

    // for i in path {
    //     let i_path = Path::new(i).to_path_buf();
    //     if !i_path.exists() {
    //         continue; // don't operate on invalid filepaths
    //     }
    //     let i_readdir = i_path.read_dir();
    //     if i_readdir.is_err() {
    //         continue; // if we can't read the directory, skip it
    //     }
    //     if !i_readdir.unwrap().next().is_some() {
    //         continue; // if the directory doesn't have anything in it, skip it
    //     }

    //     let i_opt = i_path.canonicalize()?.to_string_lossy().to_string(); // resolve symlinks as well as coercing to string
    //     if !new_order.contains(&i_opt) {
    //         new_order.push(i_opt)
    //     }
    // }

    println!("{}", new_order.join(":"));
    Ok(())
}

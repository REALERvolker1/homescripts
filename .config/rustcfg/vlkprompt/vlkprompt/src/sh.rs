use ahash;
use std::{
    env,
    path::{Path, PathBuf},
};

// This doc comment is unused, I hope you're happy to see I ditched this dumbass idea
// It takes the annoying owned HashSet antipattern type because IDGAF about your opinions.
// it's literally just meant for me to run internally as the following:
// ```
// use crate::sh::command;
// let binaries = command(ahash::HashSet::from_iter([String::from("ls"), String::from("cat"), String::from("sudo")]));
// ```

/// Check the PATH for multiple binaries. Basically a rust implementation of the shell builtin `whence -p`
pub fn command(check_binaries: &[&str]) -> ahash::HashMap<String, Option<PathBuf>> {
    // ahash::HashSet<String>
    // let mut check_binaries = binaries_list
    //     .iter()
    //     .map(|s| s.to_string())
    //     .collect::<ahash::HashSet<_>>();
    // check_binaries.iter_mut()

    let path = if let Ok(p) = env::var("PATH") {
        p
    } else {
        return check_binaries
            .iter()
            .map(|s| (s.to_string(), None))
            .collect();
    };

    // 2 hashsets. Speed > memory-efficiency
    let mut checked = check_binaries
        .iter()
        .map(|s| s.to_string())
        .collect::<ahash::HashSet<String>>();

    let mut result = checked
        .iter()
        .map(|i| (i.to_string(), None))
        .collect::<ahash::HashMap<String, Option<PathBuf>>>();

    let path_dirs = path
        .split(':')
        .filter_map(|p| Path::new(p).canonicalize().ok())
        .collect::<ahash::HashSet<_>>();

    // do all the reading and finding and whatnot as soon as possible, don't do unnecessary work
    for dir in path_dirs.iter() {
        let read_dir = if let Ok(rd) = dir.read_dir() {
            rd
        } else {
            // If we couldn't read the dir, it probably wasn't important anyway
            continue;
        };

        for direntry in read_dir.filter_map(|f| f.ok()) {
            let file_name = direntry.file_name().to_string_lossy().to_string();

            if checked.remove(&file_name) {
                let fname = file_name;
                result.insert(fname, Some(direntry.path()));
            }
        }
    }
    result
}

use crate::formatting::Color;
use std::{
    collections::{BTreeMap, BTreeSet, HashMap, HashSet},
    env, error,
    ffi::OsString,
    path::{Path, PathBuf},
};

pub fn search_path(search_binaries: &[&str]) -> HashMap<OsString, PathBuf> {
    let mut query_binaries = HashSet::new();
    for bin in search_binaries.iter() {
        query_binaries.insert(OsString::from(bin));
    }

    // Make sure there is a valid PATH variable
    let env_path = env::var("PATH").unwrap_or("/usr/local/bin:/usr/bin:/bin".to_string());
    let mut binaries: HashMap<OsString, PathBuf> = HashMap::new();

    // cached paths so we don't waste resources checking other paths
    let mut searched_paths: BTreeSet<PathBuf> = BTreeSet::new();

    let directories = env_path
        .split(":")
        .map(|i| Path::new(i))
        .filter_map(|i| i.canonicalize().ok())
        .filter(|i| i.exists())
        .collect::<Vec<PathBuf>>();

    for dir in directories.iter() {
        if searched_paths.contains(dir) {
            continue;
        } else if query_binaries.is_empty() {
            break;
        } else if let Ok(read_dir) = dir.to_owned().read_dir() {
            for file in read_dir
                .filter_map(|i| i.ok())
                .filter(|i| !i.path().is_dir())
            {
                let filekey = file.file_name();
                if query_binaries.contains(&filekey) {
                    let binary = file.path();
                    if !binaries.contains_key(&filekey) {
                        binaries.insert(filekey.to_owned(), binary.clone());
                        query_binaries.remove(&filekey);
                    }
                }
            }
            let dir_pathbuf = dir.to_owned();
            searched_paths.insert(dir_pathbuf);
        } else {
            continue;
        }
    }

    binaries
}

#[derive(Debug, Clone)]
struct ShellCommand {
    binary: PathBuf,
    args: Vec<String>,
    is_essential: bool,
}

// dnf repoquery --qf $'%{name}\0%{version}\0%{arch}\0%{description}\0%{reponame}\0%{size}\0%{enhances}' -a
// pacman -Si
#[derive(Debug, Clone)]
struct Package {
    name: String,
    version: String,
    arch: String,
    reponame: String,
    url: Option<String>,
    license: String,
    depends: HashSet<String>,
    description: Option<String>,
}

#[derive(Debug, Clone)]
struct Repository {
    name: String,
    packages: HashSet<Package>,
    repo_color: Color,
    package_color: Color,
}

#[derive(Debug, Clone)]
struct Backend {
    install: ShellCommand,
    update: ShellCommand,
    query_all: ShellCommand,
    repos: HashSet<Repository>,
}

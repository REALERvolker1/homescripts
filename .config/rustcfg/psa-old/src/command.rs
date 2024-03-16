use crate::{procinfo, style::DELIM};
use itertools::Itertools;
use std::{collections::HashSet, env, io::Write, path::Path, process};

pub fn get_pid_from_fzf_output(output: &str) -> Option<i32> {
    if !output.is_empty() {
        if let Some((tmp_pid, _junk)) = output.split_once(DELIM) {
            if let Ok(pid) = tmp_pid.parse::<i32>() {
                return Some(pid);
            }
        }
    }
    return None;
}

/// This is the menu function to show the processes as formatted strings and select them with fzf.
pub fn fzf_menu<'a, I>(
    process_format_strings: I,
    preview_cmd: Option<&'a str>,
) -> Result<String, procinfo::ProcError>
where
    I: Iterator<Item = &'a String>,
{
    let fzf_args = if let Some(p) = preview_cmd {
        vec!["--ansi", "--preview-window=down,25%", p]
    } else {
        vec!["--ansi"]
    };

    let mut fzf_process = process::Command::new("fzf")
        .args(fzf_args)
        .stdin(process::Stdio::piped())
        .stdout(process::Stdio::piped())
        .spawn()?;

    let sel_string = if let Some(fzf_stdin) = fzf_process.stdin.as_mut() {
        for s in process_format_strings {
            writeln!(fzf_stdin, "{}", s)?;
        }

        let selected = fzf_process.wait_with_output()?;
        String::from_utf8(selected.stdout)
            .unwrap_or_default()
            .trim()
            .to_owned()
    } else {
        "".to_owned()
    };

    Ok(sel_string)
}

/// Check the PATH for multiple binaries.
pub fn check_dependencies(binaries_list: &[&str]) -> Result<Vec<String>, procinfo::ProcError> {
    let mut binaries = HashSet::new();
    let mut has_binaries = Vec::new();
    {
        let _bruh = binaries_list.iter().map(|p| binaries.insert(*p));
    }

    let path = env::var("PATH")?;

    let path_dirs = path
        .split(':')
        .filter_map(|p| Path::new(p).canonicalize().ok())
        .unique()
        .collect::<Vec<_>>();

    // do all the reading and finding and whatnot as soon as possible, don't do unnecessary work
    for dir in path_dirs.iter() {
        let read_dir = if let Ok(rd) = dir.read_dir() {
            rd
        } else {
            // If we couldn't read the dir, it probably wasn't important anyway
            continue;
        };
        for file_name in read_dir
            .filter_map(|f| f.ok())
            .map(|f| f.file_name().to_string_lossy().to_string())
        {
            // afaik this is a proper use of .clone(). Since binaries is mutable, I have to clone it to remove stuff.
            for bin in binaries.clone() {
                if file_name == bin {
                    binaries.remove(bin);
                    has_binaries.push(bin.to_owned());
                }
            }
        }
    }
    if binaries.is_empty() {
        // We are done here
        Ok(has_binaries)
    } else {
        Err(procinfo::ProcError::PathBinaryError(
            binaries
                .iter()
                .map(|b| b.to_owned())
                .collect::<Vec<_>>()
                .join(", "),
        ))
    }
}

/// Run the command 'pidstat' and return the output.
pub fn pidstat(pid: i32) -> Result<(), procinfo::ProcError> {
    let pidstat = process::Command::new("pidstat")
        .args(&["-p", &pid.to_string()])
        .env("S_COLORS", "always")
        .output()?;
    print!("{}", String::from_utf8_lossy(&pidstat.stdout));
    Ok(())
}

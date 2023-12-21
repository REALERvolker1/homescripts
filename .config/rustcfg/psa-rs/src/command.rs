use crate::{proc, procinfo, style::DELIM};
use itertools::Itertools;
use serde_json;
use std::{
    collections::HashSet,
    env, fs,
    io::{self, Write},
    mem,
    path::{Path, PathBuf},
    process,
    rc::Rc,
};

/// The way this program passes data to the fzf window is by serializing and deserializing data from a file.
///
/// This is the struct that does that.
pub struct SerdeReader {
    pub processes: Vec<proc::Proc>,
    pub filepath: PathBuf,
}
impl SerdeReader {
    /// Do this if in the window function.
    pub fn new_empty() -> Result<Self, procinfo::ProcError> {
        Self::new_with_procs(Vec::new())
    }
    /// Only do this in the main function when you have all the processes
    pub fn new_with_procs(processes: Vec<proc::Proc>) -> Result<Self, procinfo::ProcError> {
        let path_string = env::var("XDG_RUNTIME_DIR").unwrap_or("/tmp".to_string());
        let dir_path = Path::new(&path_string);

        // make sure it exists and I can write to it
        if !dir_path.exists() {
            fs::create_dir_all(dir_path)?;
        }
        if !dir_path.is_dir() || dir_path.metadata()?.permissions().readonly() {
            return Err(procinfo::ProcError::CustomError(
                "Invalid directory!".to_owned(),
            ));
        }
        // join filepath, but don't do anything with that yet.
        let filepath = dir_path.join("cache.json");

        Ok(Self {
            processes,
            filepath: filepath,
        })
    }
    /// Removes the cachefile because that's in tmpfs and wasting ram
    pub fn cleanup(self) -> io::Result<()> {
        if self.filepath.exists() {
            fs::remove_file(&self.filepath)?;
        }
        Ok(())
    }
    /// serialize into a file so I can cache the output for the fzf view screen
    pub fn to_file(&self) -> io::Result<()> {
        // cleanup function was probably skipped.
        if self.filepath.exists() {
            fs::remove_file(&self.filepath)?;
        }
        let mut file = io::BufWriter::new(fs::File::create(&self.filepath)?);
        serde_json::to_writer(&mut file, &self.processes)?;
        Ok(())
    }
    /// reads processes from a file and mutates self. Please access results from self.processes
    pub fn from_file(&mut self) -> Result<(), procinfo::ProcError> {
        let reader = io::BufReader::new(fs::File::open(&self.filepath)?);
        self.processes = serde_json::from_reader(reader)?;
        Ok(())
    }

    pub fn get_process_by_pid(&self, pid: i32) -> Option<proc::Proc> {
        if let Some(process) = self.processes.iter().find(|p| p.pid == pid) {
            Some(process.to_owned())
        } else {
            None
        }
    }
}

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
    preview_cmd: &str,
) -> Result<String, procinfo::ProcError>
where
    I: Iterator<Item = &'a String>,
{
    let fzf_args = ["--ansi", "--preview-window=down,25%", preview_cmd];
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

/// A function to get the terminal width for the preferred width. If it cannot get the terminal width, then it will return usize::MAX, basically disabling it anyways.
pub fn terminal_width() -> usize {
    let size_cmd_output = process::Command::new("tput").arg("cols").output();

    if let Ok(size_cmd) = size_cmd_output {
        let stdout = String::from_utf8_lossy(&size_cmd.stdout);
        if let Ok(cols) = stdout.trim().parse::<usize>() {
            cols
        } else {
            usize::MAX
        }
    } else {
        usize::MAX
    }
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

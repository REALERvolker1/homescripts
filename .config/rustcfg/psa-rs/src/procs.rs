use nix;
use procfs;
use std::{
    env,
    path::{Path, PathBuf},
    rc,
};
use users;

/// This struct contains all the information about a single process.
/// It does not implement `Clone` because I am learning how to use rust's `rc` crate.
#[derive(Debug)]
pub struct Process {
    pub pid: i32,
    pub parent_pid: i32,
    pub name: String,
    pub state: procfs::process::ProcState,
    pub user: users::User,
    pub executable: Option<PathBuf>,
    pub args: Vec<String>,
}
impl Default for Process {
    fn default() -> Self {
        Self {
            pid: 0,
            parent_pid: 0,
            name: String::new(),
            state: procfs::process::ProcState::Dead,
            user: String::new(),
            executable: None,
            args: Vec::new(),
        }
    }
}
impl Process {
    pub fn from_procfs_process(
        process: procfs::process::Process,
    ) -> Result<String, procfs::ProcError> {
        // required /proc files to read for the information
        let status = process.status()?;
        let stat = process.stat()?;

        let pid = process.pid();
        // argzero
        let name = status.name;
        // if it is running, sleeping, zombie, etc
        let state = stat.state()?;

        let uid = process.uid()?;
        let user = users::get_user_by_uid(uid).unwrap().name();

        let executable = process.exe()?;
        let args = process.cmdline().unwrap_or_default();
        let parent_pid = status.ppid;

        Ok(format!(
            "pid: {:?} state: {:?} name: {:?} user: {} nixname: {:?}",
            pid, state, name, user, gotname
        ))
    }
}

pub fn refresh() -> Result<Vec<String>, procfs::ProcError> {
    let processes = procfs::process::all_processes()?
        .filter_map(|i| i.ok())
        .map(|i| Process::from_procfs_process(i))
        .filter_map(|i| i.ok())
        .collect::<Vec<String>>();

    Ok(processes)
}

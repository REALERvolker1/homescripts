use crate::*;

/// The PID of the kernel worker process.
///
/// I'm trying to
const WORKER_PROCS: [i32; 2] = [3, 2];
// const WORKER_PROC_NAMES: [&str; 3] = ["kthreadd", "kworker", "irq/"];

fn is_kernel_proc(ppid: i32, pid: i32) -> bool {
    for i in WORKER_PROCS {
        if ppid == i || pid == i {
            return true;
        }
    }
    false
}

#[derive(Debug)]
pub struct ProcInfoCache {
    /// All the errors of the last refresh. This is cleared on refresh.
    pub errors: Vec<BruhMoment>,
    pub processes: HashMap<Pid, ProcessInfo>,
}
impl Default for ProcInfoCache {
    fn default() -> Self {
        Self {
            errors: Vec::new(),
            processes: HashMap::new(),
        }
    }
}
impl ProcInfoCache {
    // pub fn refresh(mut self) -> Result<Self, procfs::ProcError> {
    //     let procs = Self::get_procs()?;
    //     self.refresh_with_procs(procs.into_iter());
    //     Ok(self)
    // }
    /// Get all the processes. This is here so there is one shared method returning a process list.
    pub fn get_procs() -> Result<Vec<ProcessInfo>, procfs::ProcError> {
        let procs = procfs::process::all_processes()?
            .filter_map(|p| p.ok())
            .filter_map(|p| processes::ProcessInfo::from_procfs_process(p, ARGS.filter).ok())
            .collect_vec();

        Ok(procs)
    }
    pub fn refresh_with_procs<I>(&mut self, procs: I)
    where
        I: Iterator<Item = ProcessInfo>,
    {
        for p in procs {
            self.processes.insert(p.pid, p);
        }
    }
    /// Get the process info, if it exists.
    /// If the cache has not been refreshed at all since initialization, this will return `None`.
    pub fn get(&self, pid: Pid) -> Option<&ProcessInfo> {
        self.processes.get(&pid)
    }
    /// Get a random process, for testing. Panics if there are no processes.
    pub fn get_random(&self) -> &ProcessInfo {
        if let Some(p) = self.processes.values().next() {
            p
        } else {
            panic!("No processes in cache?");
        }
    }
}
impl fmt::Display for ProcInfoCache {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "ProcInfoCache
---------------
Process count: {}
Max PID: {}
Init: {}",
            self.processes.len(),
            self.processes.keys().max().unwrap_or(&PID_NULL),
            self.processes
                .get(&Pid::from(1))
                .map_or_else(|| "N/A", |i| i.name.as_str())
        )
    }
}

/// The minimum amount of information I need to get about a process.
#[derive(Debug, PartialEq, Eq)]
pub struct ProcessInfo {
    pid: Pid,
    parent_pid: Pid,
    ruid: Uid,
    euid: Option<Uid>,
    num_threads: i64,
    state: RecognizedStates,
    name: String,
    binary_path: String,
    args: Vec<String>,
    fmt_args: Option<Vec<String>>,
}
impl ProcessInfo {
    /// Does what it says on the tin
    pub fn from_procfs_process(
        process: procfs::process::Process,
        filter_type: cli::FilterType,
    ) -> Bruh<Self> {
        let stat = process.stat()?;
        let status = process.status()?;
        let ruid = status.ruid.into();
        let euid = status.euid.into();

        let should_skip = match filter_type {
            cli::FilterType::IncludeKernel => false,
            cli::FilterType::All => is_kernel_proc(status.ppid, stat.pid),
            cli::FilterType::Mine => {
                is_kernel_proc(status.ppid, stat.pid) && (ruid == *MY_UID || euid == *MY_UID)
            }
        };
        // debug!(
        //     "parent {} {} should_skip: {should_skip}",
        //     &status.ppid, &status.name
        // );

        if should_skip {
            return Err(BruhMoment::Filter);
        }

        let euid = if euid != ruid { Some(euid) } else { None };

        let state_char = status
            .state
            .chars()
            .next()
            .unwrap_or_default()
            .to_string()
            .to_ascii_uppercase();

        Ok(Self {
            pid: Pid::from(stat.pid),
            parent_pid: Pid::from(status.ppid),
            ruid,
            euid,
            num_threads: stat.num_threads,
            state: RecognizedStates::from_str(&state_char),
            name: status.name,
            binary_path: stat.comm,
            args: process.cmdline().unwrap_or_default(),
            fmt_args: None,
        })
    }
    /// A getter for this process's pid
    pub fn pid(&self) -> Pid {
        self.pid
    }
    /// A getter for this process's parent pid
    pub fn ppid(&self) -> Pid {
        self.parent_pid
    }
    /// A getter for this process's RUID (real UID)
    pub fn uid(&self) -> Uid {
        self.ruid
    }
    /// A getter for this process's EUID (effective UID)
    pub fn euid(&self) -> Option<Uid> {
        self.euid
    }
    /// A getter for this process's UID and optional EUID
    pub fn users(&self) -> Vec<Uid> {
        if let Some(e) = self.euid {
            vec![self.ruid, e]
        } else {
            vec![self.ruid]
        }
    }
    /// A getter for this process's number of threads
    pub fn num_threads(&self) -> i64 {
        self.num_threads
    }
    /// A getter for this process's state
    pub fn state(&self) -> RecognizedStates {
        self.state
    }
    /// A getter for this process's name
    pub fn name(&self) -> &str {
        &self.name
    }
    /// A getter for this process's binary path
    pub fn binary_path(&self) -> &str {
        &self.binary_path
    }
    /// A getter for this process's arguments
    pub fn args(&self) -> Vec<&str> {
        self.args.iter().map(|s| s.as_str()).collect_vec()
    }
}

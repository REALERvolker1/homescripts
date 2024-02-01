use crate::*;

/// The PID of the kernel worker process.
const WORKER_PROCS: [i32; 2] = [3, 2];

fn not_kernel_proc(name: &str) -> bool {
    for i in ["kthreadd", "kworker"] {
        if name.contains(i) {
            return false;
        }
    }
    true
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum UserGroup {
    Real(Uid),
    /// The Real UID and Effective UID, in order.
    RealEffective(Uid, Uid),
}
impl UserGroup {
    pub fn get(&self) -> Box<[Uid]> {
        match *self {
            processes::UserGroup::Real(u) => Box::new([u]),
            processes::UserGroup::RealEffective(u, e) => Box::new([u, e]),
        }
    }
    pub fn format_uid(&self, user_cache: users::UserCache) -> String {
        match *self {
            processes::UserGroup::Real(u) => {
                if let Some(user) = user_cache.get_user(u) {
                    user.format_self().to_string()
                } else {
                    Color::LightRed
                        .bold()
                        .paint(format!("Unable to find user: {u}"))
                        .to_string()
                }
            }
            processes::UserGroup::RealEffective(u, e) => {
                match (user_cache.get_user(u), user_cache.get_user(e)) {
                    (Some(real_user), Some(effective_user)) => {
                        format!(
                            "Real user: {}, effective user: {}",
                            real_user.format_self(),
                            effective_user.format_self()
                        )
                    }
                    (Some(real_user), None) => {
                        format!(
                            "Real user: {}, EUID not found: {e}",
                            real_user.format_self(),
                        )
                    }
                    (None, Some(effective_user)) => {
                        format!(
                            "Effective user: {}, RUID not found: {u}",
                            effective_user.format_self(),
                        )
                    }
                    (None, None) => Color::LightRed
                        .bold()
                        .paint(format!("RUID ({u}) and EUID ({e}) not found"))
                        .to_string(),
                }
            }
        }
    }
}

#[derive(Debug)]
pub struct ProcInfoCache {
    /// This current process's pid. Here for convenience.
    pub my_pid: Pid,
    /// All the errors of the last refresh. This is cleared on refresh.
    pub errors: Vec<BruhMoment>,
    pub processes: HashMap<Pid, ProcessInfo>,
}
impl Default for ProcInfoCache {
    fn default() -> Self {
        Self {
            my_pid: Pid::this(),
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
My PID: {}
Init: {}",
            self.processes.len(),
            self.processes.keys().max().unwrap_or(&PID_NULL),
            self.my_pid,
            self.processes
                .get(&Pid::from_raw(1))
                .map_or_else(|| "N/A", |i| i.name.as_str())
        )
    }
}

/// The minimum amount of information I need to get about a process.
#[derive(Debug, PartialEq, Eq)]
pub struct ProcessInfo {
    pid: Pid,
    parent_pid: Pid,
    users: UserGroup,
    num_threads: i64,
    state: RecognizedStates,
    name: String,
    binary_path: String,
    args: Vec<String>,
    fmt_args: Option<Vec<String>>,
}
impl ProcessInfo {
    /// A getter for this process's pid
    pub fn pid(&self) -> Pid {
        self.pid
    }
    /// A getter for this process's parent pid
    pub fn ppid(&self) -> Pid {
        self.parent_pid
    }
    /// A getter for this process's UID and optional EUID
    pub fn users(&self) -> UserGroup {
        self.users
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
    pub fn from_procfs_process(
        process: procfs::process::Process,
        filter_type: cli::FilterType,
    ) -> Bruh<Self> {
        let stat = process.stat()?;
        let status = process.status()?;
        let uid = status.ruid.into();
        let euid = status.euid.into();

        let should_skip = match filter_type {
            cli::FilterType::IncludeKernel => true,
            cli::FilterType::All => not_kernel_proc(&status.name),
            cli::FilterType::Mine => {
                not_kernel_proc(&status.name) && (uid != *MY_UID || euid != *MY_UID)
            }
        };

        if should_skip {
            return Err(BruhMoment::Filter);
        }

        let users = if euid != uid {
            UserGroup::RealEffective(uid, euid)
        } else {
            UserGroup::Real(uid)
        };

        let state_char = status
            .state
            .chars()
            .next()
            .unwrap_or_default()
            .to_string()
            .to_ascii_uppercase();

        Ok(Self {
            pid: Pid::from_raw(stat.pid),
            parent_pid: Pid::from_raw(status.ppid),
            users,
            num_threads: stat.num_threads,
            state: RecognizedStates::from_str(&state_char),
            name: status.name,
            binary_path: stat.comm,
            args: process.cmdline().unwrap_or_default(),
            fmt_args: None,
        })
    }
}

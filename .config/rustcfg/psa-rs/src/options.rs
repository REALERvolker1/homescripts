use crate::{command, proc, procinfo, style};
use nix::{sys::signal, unistd::Pid};
use procfs;
use std::rc::Rc;
// macro_rules! capkill {
//     ($map:ident) => {
//         $map.insert("Kill this process", AvailableOptions::Kill)
//     };
// }
#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum AvailableOptions {
    Kill,
    ProcTree,
    PidStat,
    PrettyPrint,
    FullStats,
    Undefined,
}
impl AvailableOptions {
    /// format this option as a string suitable for use in fzf
    pub fn describe(&self) -> Option<String> {
        if self == &Self::Undefined {
            None
        } else {
            Some(
                match self {
                    Self::FullStats => "Print verbose process details",
                    Self::PrettyPrint => "Pretty-print process",
                    Self::PidStat => "Run 'pidstat' on this process",
                    Self::ProcTree => "Print the process tree",
                    Self::Kill => "Kill this process",
                    Self::Undefined => unreachable!(),
                }
                .to_owned(),
            )
        }
    }
    pub fn from_description(description: &str) -> Self {
        match description {
            "Print verbose process details" => Self::FullStats,
            "Pretty-print process" => Self::PrettyPrint,
            "Run 'pidstat' on this process" => Self::PidStat,
            "Print the process tree" => Self::ProcTree,
            "Kill this process" => Self::Kill,
            _ => Self::Undefined,
        }
    }
    /// Run the command associated with this option
    pub fn run_command(&self, process: Rc<proc::Proc>) -> Result<(), procinfo::ProcError> {
        match self {
            Self::FullStats => print_pid_verbosely(process.pid),
            Self::PrettyPrint => Ok(println!("{}", process.info_style())),
            Self::PidStat => command::pidstat(process.pid),
            Self::ProcTree => style::print_process_tree(process),
            Self::Kill => KillOptions::kill_process(process),
            Self::Undefined => Ok(()),
        }
    }
    /// Get all the actions that I can take
    pub fn get_capabilities(process: &proc::Proc) -> Vec<Self> {
        let mut capabilities = Vec::new();

        capabilities.push(AvailableOptions::PrettyPrint);
        capabilities.push(AvailableOptions::ProcTree);

        // let mut depcheck_deps = vec!["pidstat"];
        // don't have to use sudo to kill my own processes
        if process.uid == procinfo::USER.uid {
            capabilities.push(AvailableOptions::Kill);
        }
        // else {
        // depcheck_deps.push("sudo")
        // }

        // These options require external dependencies
        if let Ok(_cmds) = command::check_dependencies(&["pidstat"]) {
            capabilities.push(AvailableOptions::PidStat);
            // for cmd in cmds {
            //     match cmd.as_str() {
            //         "pidstat" => capabilities.push(AvailableOptions::PidStat),
            //         // does not push twice, as depchecks only checks for sudo if it isn't mine
            //         "sudo" => capabilities.push(AvailableOptions::Kill),
            //         _ => continue,
            //     };
            // }
        }
        capabilities.push(AvailableOptions::FullStats);

        capabilities
    }
}

macro_rules! procpush {
    ($vector:ident, $p:ident, $operation:ident) => {
        let op = $p.$operation();
        if op.is_ok() {
            $vector.push(format!(
                "\n\x1b[1m=== {} ===\x1b[0m\n\n{:#?}",
                stringify!($operation),
                op.unwrap()
            ));
        }
    };
}

/// Prints the process information for a procfs::Process
fn print_pid_verbosely(pid: i32) -> Result<(), procinfo::ProcError> {
    let tmp_process = procfs::process::Process::new(pid)?;
    let process = Rc::new(tmp_process);
    let mut printmap = Vec::new();

    // procpush!(printmap, process, arp);
    procpush!(printmap, process, autogroup);
    // procpush!(printmap, process, auxv);
    procpush!(printmap, process, cgroups);
    procpush!(printmap, process, cmdline);
    procpush!(printmap, process, coredump_filter);
    procpush!(printmap, process, cwd);
    procpush!(printmap, process, dev_status);
    procpush!(printmap, process, environ);
    procpush!(printmap, process, fd);
    procpush!(printmap, process, fd_count);
    procpush!(printmap, process, io);
    // bool
    // procpush!(printmap, process, is_alive);
    procpush!(printmap, process, limits);
    procpush!(printmap, process, loginuid);
    // nerd shit
    // procpush!(printmap, process, maps);
    // procpush!(printmap, process, mem);
    // does not impl Debug
    // procpush!(printmap, process, mountinfo);
    procpush!(printmap, process, mountstats);
    procpush!(printmap, process, namespaces);
    procpush!(printmap, process, oom_score);
    // does not impl Debug
    // procpush!(printmap, process, pagemap);
    // i32
    // procpush!(printmap, process, pid);
    procpush!(printmap, process, root);
    procpush!(printmap, process, route);
    procpush!(printmap, process, schedstat);
    // nerd shit
    // procpush!(printmap, process, smaps);
    procpush!(printmap, process, smaps_rollup);
    // buggy
    // procpush!(printmap, process, snmp);
    // procpush!(printmap, process, snmp6);
    procpush!(printmap, process, stat);

    procpush!(printmap, process, statm);
    procpush!(printmap, process, status);
    procpush!(printmap, process, tasks);
    // holy shit that's a lot of output garbage
    // procpush!(printmap, process, tcp);
    // procpush!(printmap, process, tcp6);
    // procpush!(printmap, process, udp);
    // procpush!(printmap, process, udp6);
    procpush!(printmap, process, uid);
    // lots of output
    // procpush!(printmap, process, unix);
    procpush!(printmap, process, wchan);

    println!("{}", printmap.join("\n"));

    Ok(())
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
enum KillOptions {
    Kill,
    Terminate,
    Interrupt,
}
impl KillOptions {
    fn from_description(description: &str) -> Option<Self> {
        match description {
            "[SIGKILL] (DANGER) Forcibly kill this process" => Some(Self::Kill),
            "[SIGTERM] Terminate this process" => Some(Self::Terminate),
            "[SIGINT]  Interrupt this process (Basically Ctrl-C)" => Some(Self::Interrupt),
            _ => None,
        }
    }
    fn to_description(&self) -> String {
        match self {
            Self::Kill => "[SIGKILL] (DANGER) Forcibly kill this process",
            Self::Terminate => "[SIGTERM] Terminate this process",
            Self::Interrupt => "[SIGINT]  Interrupt this process (Basically Ctrl-C)",
        }
        .to_owned()
    }
    fn kill_process(proc: Rc<proc::Proc>) -> Result<(), procinfo::ProcError> {
        let options = vec![
            Self::to_description(&Self::Terminate),
            Self::to_description(&Self::Interrupt),
            Self::to_description(&Self::Kill),
        ];
        if let Ok(selected_description) = command::fzf_menu(options.iter(), None) {
            if let Some(action) = Self::from_description(&selected_description) {
                let signal = match action {
                    Self::Terminate => signal::SIGTERM,
                    Self::Interrupt => signal::SIGINT,
                    Self::Kill => signal::SIGKILL,
                };

                if signal::kill(Pid::from_raw(proc.pid), signal).is_ok() {
                    println!(
                        "Sent signal [{:?}] to process: ({}) {}",
                        &action, proc.pid_styled, proc.name_styled
                    );
                } else {
                    return Err(procinfo::ProcError::CustomError(format!(
                        "Failed to kill process: ({}) {}",
                        proc.pid_styled, proc.name_styled
                    )));
                }
            }
        }

        Ok(())
    }
}

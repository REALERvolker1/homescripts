use crate::{command, proc, procinfo};
use procfs;
use std::{
    collections::HashMap,
    fmt::{Debug, Display},
    os, process,
    rc::Rc,
};
#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum AvailableOptions {
    KillSudo,
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
                    Self::PidStat => "Run the `pidstat` command on this process",
                    Self::ProcTree => "Print the process tree",
                    Self::Kill => "Kill this process",
                    Self::KillSudo => "[sudo required] Kill this process with root permissions",
                }
                .to_owned(),
            )
        }
    }
    /// Get self from description (parsing input from fzf)
    pub fn from_description(description: &str) -> Self {
        match description {
            "Print verbose process details" => Self::FullStats,
            "Pretty-print process" => Self::PrettyPrint,
            "Run the `pidstat` command on this process" => Self::PidStat,
            "Print the process tree" => Self::ProcTree,
            "Kill this process" => Self::Kill,
            "[sudo required] Kill this process with root permissions" => Self::KillSudo,
            _ => Self::Undefined,
        }
    }
    pub fn run_command(&self, process: proc::Proc) -> Result<(), procinfo::ProcError> {
        Ok(())
    }
    pub fn get_capabilities() -> Vec<Self> {
        let mut capabilities = Vec::new();
        // These require external dependencies
        if let Ok(cmds) = command::check_dependencies(&["pidstat", "sudo"]) {
            for cmd in cmds {
                let cap = match cmd.as_str() {
                    "pidstat" => Self::PidStat,
                    "sudo" => Self::KillSudo,
                    _ => continue,
                };
                capabilities.push(cap);
            }
        }

        capabilities
    }
}

// #[derive(Debug, Clone, Copy)]
// pub struct CapabilitySet {
//     full_stats: AvailableOptions,
//     pretty_print: AvailableOptions,
//     pidstat: Option<AvailableOptions>,
//     proc_tree: AvailableOptions,
//     kill: AvailableOptions,
//     kill_sudo: Option<AvailableOptions>,
// }
// impl Default for CapabilitySet {
//     fn default() -> Self {
//         Self {
//             full_stats: None,
//             pretty_print: None,
//             pidstat: AvailableOptions::PidStat,
//             proc_tree: AvailableOptions::PidStat,
//             kill: AvailableOptions::PidStat,
//             kill_sudo: AvailableOptions::PidStat,
//         }
//     }
// }
// impl CapabilitySet {
//     pub fn get_capabilities() -> Self {
//         let mut capabilities = Self::default();
//         // These require external dependencies
//         if let Ok(cmds) = command::check_dependencies(&["pidstat", "sudo"]) {
//             for cmd in cmds {
//                 let cap = match cmd.as_str() {
//                     "pidstat" => capabilities.pidstat = Some(AvailableOptions::PidStat),
//                     "sudo" => capabilities.kill_sudo = Some(AvailableOptions::KillSudo),
//                 };
//             }
//         }

//         capabilities
//     }
// }

macro_rules! procpush {
    ($vector:ident, $p:ident, $operation:ident) => {
        let op = $p.$operation().ok();
        if op.is_some() {
            $vector.push(format!(
                "\n\n\x1b[1m=== {} ===\x1b[0m\n\n{:?}",
                stringify!($operation),
                op
            ));
        }
    };
}

pub fn print_pid_verbosely(pid: i32) -> Result<(), procfs::ProcError> {
    let tmp_process = procfs::process::Process::new(pid)?;
    let process = Rc::new(tmp_process);
    let mut printmap = Vec::new();

    procpush!(printmap, process, arp);
    procpush!(printmap, process, autogroup);
    procpush!(printmap, process, auxv);
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
    procpush!(printmap, process, maps);
    procpush!(printmap, process, mem);
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
    procpush!(printmap, process, smaps);
    procpush!(printmap, process, smaps_rollup);
    // buggy
    // procpush!(printmap, process, snmp);
    // procpush!(printmap, process, snmp6);
    procpush!(printmap, process, stat);

    procpush!(printmap, process, statm);
    procpush!(printmap, process, status);
    procpush!(printmap, process, tasks);
    procpush!(printmap, process, tcp);
    procpush!(printmap, process, tcp6);
    procpush!(printmap, process, udp);
    procpush!(printmap, process, udp6);
    procpush!(printmap, process, uid);
    procpush!(printmap, process, unix);
    procpush!(printmap, process, wchan);

    println!("{}", printmap.join("\n"));

    Ok(())
}

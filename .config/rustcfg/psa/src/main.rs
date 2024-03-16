mod action;
mod cli;
// mod config;
mod proc;

use std::{
    sync::{mpsc, Arc},
    thread,
};

#[cfg(debug_assertions)]
use std::time::Instant;

use crate::proc::{FzfOutput, Process};
use ahash::{HashMap, HashMapExt};
use once_cell::sync::Lazy;
use procfs::{ProcError, ProcResult};

pub static CONFIG: Lazy<cli::Config> = Lazy::new(cli::Config::new);

pub static MENU_SELECTOR_COMMAND: Lazy<action::SelectorCommand> = Lazy::new(|| {
    let mut args = CONFIG.pipe_command.args.clone();
    args.push(format!(
        "--preview={} --format-tab-delimited {{}} --{}color",
        std::env::current_exe().unwrap().display(),
        if CONFIG.color { "" } else { "no-" }
    ));

    action::SelectorCommand {
        bin: CONFIG.pipe_command.bin.clone(),
        args,
    }
});

fn main() -> ProcResult<()> {
    if let Some(s) = CONFIG.format_tab_delimited.as_ref() {
        let out_string = match FzfOutput::from_output(s) {
            Ok(p) => p.format_each().join("\n"),
            Err(e) => e.to_string(),
        };

        println!("{out_string}");
        std::process::exit(0);
    }

    // This function is recursive!
    action::Action::Ask.act(menu()?)?;
    Ok(())
}

/// My own implementation of Rayon, with blackjack and hookers
///
/// This function is recursive, so I have to do a lot of scoping so that everything drops. I don't want to cause too much of a memory leak.
pub fn menu() -> ProcResult<FzfOutput> {
    #[cfg(debug_assertions)]
    let inst = Instant::now();

    let queues = {
        let num_cpus = {
            let parallelism = thread::available_parallelism()?.get() as usize;
            if parallelism > 8 {
                parallelism / 2
            } else {
                parallelism
            }
        };

        let mut queues = (0..num_cpus)
            .map(|_| Vec::new())
            .collect::<Vec<Vec<procfs::process::Process>>>();

        // TODO: Some processes have subprocesses that have the same args and paths to colorize, and are next to each other.
        // This makes more work and memory consumption as each thread might have to colorize the same paths for similar procs.
        // Since I only multithread because coloring paths is expensive, I would rather have like with like.
        let mut counter = 0;
        for p in procfs::process::all_processes()?.filter_map(|p| p.ok()) {
            if counter >= num_cpus {
                counter = 0;
            }
            queues[counter].push(p);
            counter += 1;
        }

        queues
    };

    // queues is moved into this block
    let processes = {
        let (temporary_sender, receiver) = mpsc::channel();

        let sender = Arc::new(temporary_sender);

        // calling .collect() here makes the handles run, and collects them into a Vec of join handles so I can ensure the threads are finished
        let handles = queues
            .into_iter()
            .map(|vp| {
                let my_sender = Arc::clone(&sender);
                thread::spawn(move || {
                    // my own queue per thread, so I don't have to have a fuckton of Lazy cells (basically rwlocks or mutexes) everywhere.
                    // This is the reason why the proc.rs apis are so fucked up
                    let mut cache = Some(HashMap::new());
                    for p in vp {
                        match Process::from_procfs_process(&p, &mut cache) {
                            Ok(Some(r)) => my_sender.send(r).unwrap(),
                            Ok(None) => (), // ignored
                            Err(e) => eprintln!("Failed to map process: {e}"),
                        }
                    }
                })
            })
            .collect::<Vec<_>>();

        // so I'm not waiting forever, and the sender arc is dropped when all the threads are done
        std::mem::drop(sender);

        let mut processes = Vec::new();

        while let Ok(p) = receiver.recv() {
            processes.push(p);
        }

        // make sure that all the threads are done
        handles.into_iter().for_each(|t| t.join().unwrap());

        processes.sort_by(|a, b| a.pid.cmp(&b.pid));

        processes
    };

    #[cfg(debug_assertions)]
    eprintln!("Processed in {:?}", inst.elapsed());

    let call_menu_again = {
        let fzf_stdin = processes
            .iter()
            .map(|p| p.format_for_fzf())
            .collect::<Vec<_>>();

        let chosen_process = MENU_SELECTOR_COMMAND.exec(fzf_stdin)?;

        match FzfOutput::from_output(&chosen_process) {
            Ok(p) => Some(Ok(p)),
            Err(e) => match e {
                // the process might have died while I was scrolling over to it
                ProcError::NotFound(_) => None,
                _ => Some(Err(e)),
            },
        }
    };

    if let Some(r) = call_menu_again {
        r
    } else {
        menu()
    }
}

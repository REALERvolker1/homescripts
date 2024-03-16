mod action;
mod cli;
// mod config;
mod proc;

use std::{
    sync::{mpsc, Arc},
    thread,
    time::Instant,
};

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
pub fn menu() -> ProcResult<FzfOutput> {
    let inst = Instant::now();
    let parallelism = thread::available_parallelism()?.get() as usize;
    let num_cpus = if parallelism > 8 {
        parallelism / 2
    } else {
        parallelism
    };

    let mut queues = (0..num_cpus)
        .map(|_| Vec::new())
        .collect::<Vec<Vec<procfs::process::Process>>>();

    let mut counter = 0;
    for p in procfs::process::all_processes()?.filter_map(|p| p.ok()) {
        if counter >= num_cpus {
            counter = 0;
        }
        queues[counter].push(p);
        counter += 1;
    }

    let mut handles = Vec::new();

    let (tx, rx) = mpsc::channel();
    let sender = Arc::new(tx);

    queues.into_iter().for_each(|vp| {
        let sender = sender.clone();
        let handle = thread::spawn(move || {
            // my own queue per thread, so I don't have to have a fuckton of mutexes everywhere.
            // This is the reason why the proc.rs apis are so fucked up
            let mut queue = HashMap::new();
            for p in vp {
                match Process::from_procfs_process(&p, &mut queue) {
                    Ok(Some(r)) => sender.send(r).unwrap(),
                    Ok(None) => (), // ignored
                    Err(e) => eprintln!("Failed to map process: {e}"),
                }
            }
        });

        handles.push(handle)
    });

    std::mem::drop(sender); // so the receiver doesn't wait forever

    /*
        let mut processes = procfs::process::all_processes()?
            .par_bridge()
            .filter_map(|p| p.ok())
            .filter_map(|p| match Process::from_procfs_process(&p) {
                Ok(r) => r,
                Err(e) => {
                    eprintln!("Failed to map process: {e}");
                    None
                }
            })
            .collect::<Vec<_>>();
    */

    let mut processes = Vec::new();

    while let Ok(p) = rx.recv() {
        processes.push(p);
    }

    handles.into_iter().for_each(|t| t.join().unwrap());

    processes.sort_by(|a, b| a.pid.cmp(&b.pid));

    let stop = inst.elapsed();
    println!("Processed in {stop:?}");

    let fzf_stdin = processes
        .iter()
        .map(|p| p.format_for_fzf())
        .collect::<Vec<_>>();

    let result = MENU_SELECTOR_COMMAND.exec(fzf_stdin)?;

    match FzfOutput::from_output(&result) {
        Ok(p) => Ok(p),
        Err(e) => match e {
            // the process might have died while I was scrolling over to it
            ProcError::NotFound(_) => menu(),
            _ => Err(e),
        },
    }
}

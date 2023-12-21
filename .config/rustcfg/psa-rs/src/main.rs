use std::{env, rc::Rc};
use users;

mod command;
mod options;
mod proc;
mod procinfo;
mod style;

/// Common PIDs of kernel processes (like [kworker/kslavelabor] and [kthreadd])
const KERNEL_OR_INIT_PIDS: [i32; 3] = [0, 1, 2];

fn main() -> Result<(), procinfo::ProcError> {
    let mut args_iter = env::args().skip(1);
    if let Some(first_arg) = args_iter.next() {
        match first_arg.as_str() {
            "--all" => main_process_screen(true)?,
            "--internal-preview-window" => {
                let args = args_iter.collect::<Vec<String>>().join(" ");
                // show_preview_window(&args)?
                show_preview_window_nocache(&args)?
            }
            _ => {
                let help_text = vec![
                    "--all\tShows all processes, not just those owned by you",
                    "",
                    "Running this command without any args will show all processes owned by the current user",
                ];
                println!(
                    "Unknown arg: '{}'\nUsage: {} [options]\n{}",
                    first_arg,
                    env!("CARGO_PKG_NAME"),
                    help_text.join("\n")
                );
            }
        }
    } else {
        // no args passed
        main_process_screen(false)?;
    }
    Ok(())
}

/// The preview window, with more up to date information, without a cachefile
fn show_preview_window_nocache(fzf_output: &str) -> Result<(), procinfo::ProcError> {
    if let Some(pid) = command::get_pid_from_fzf_output(fzf_output) {
        let process = proc::Proc::from_pid(pid)?;
        println!("{}", process.info_style());
    }
    Err(procinfo::ProcError::CustomError(
        "Could not find process!".to_owned(),
    ))
}

/*
/// The preview window preview command, using a cachefile that shows a snapshot of the machine state
///
/// as it was when the program started running
fn show_preview_window(fzf_output: &str) -> Result<(), procinfo::ProcError> {
    let mut serde_reader = command::SerdeReader::new_empty()?;
    serde_reader.from_file()?;
    if let Some(pid) = command::get_pid_from_fzf_output(fzf_output) {
        if let Some(proc) = serde_reader.get_process_by_pid(pid) {
            println!("{}", proc.info_style());
            return Ok(());
        }
    }
    Err(procinfo::ProcError::CustomError(
        "Could not find process!".to_owned(),
    ))
}
*/

/// the real main() function
fn main_process_screen(show_all: bool) -> Result<(), procinfo::ProcError> {
    // make sure I have the required dependencies
    command::check_dependencies(&["fzf", "tput"])?;

    // do this first. If it fails, then I won't have to do more computation.
    let preview_cmd = if let Some(exe) = env::current_exe()?.to_str() {
        format!("--preview={} --internal-preview-window {{}}", exe)
    } else {
        "--preview=echo {}".to_owned()
    };

    let user_cache = if show_all {
        procinfo::UserList::all()
    } else {
        procinfo::UserList::just_me()
    };

    // This is intended to make it so the args cut off at a somewhat reasonable width.
    // It will not be the full width, but ehh idc
    let preferred_width_base = command::terminal_width();

    let mut style_cache = proc::StyleCache::default();
    let my_uid = users::get_current_uid();

    let processes = procfs::process::all_processes()?
        .into_iter()
        .filter_map(|p| p.ok())
        .filter_map(|p| {
            let uid = if let Ok(u) = p.uid() {
                u
            } else {
                return None;
            };
            if !show_all {
                if KERNEL_OR_INIT_PIDS.contains(&p.pid) || uid != my_uid {
                    return None;
                }
            }
            if let Some(u) = user_cache.get_user(uid) {
                proc::Proc::from_procfs_proc(p, u, &mut style_cache, preferred_width_base).ok()
            } else {
                None
            }
        })
        .collect::<Vec<_>>();

    // put the output strings here because the processes are moved into the SerdeReader
    let console_output = processes
        .iter()
        .map(|p| p.console_style())
        .collect::<Vec<_>>();

    // Make a new SerdeReader with the processes
    // let serde_reader = command::SerdeReader::new_with_procs(processes)?;
    // put everything into a file for this program to read
    // serde_reader.to_file()?;

    // fzf_menu
    let selected_proc =
        if let Ok(selected_line) = command::fzf_menu(console_output.iter(), &preview_cmd) {
            proc_from_fzf_output(&selected_line)?
        } else {
            println!("No process selected");
            return Ok(());
        };
    // options::print_verbose(1115)?;
    let mut opts = options::PrintMap::new();
    opts.fmt_pid(1115)?;

    // remove the tmpfile
    // serde_reader.cleanup()?;

    Ok(())
}

/// Show the options for each process
fn process_opts(process: proc::Proc, show_all: bool) -> Result<(), procinfo::ProcError> {
    // This is a list of possible options. Can be expanded upon
    let mut options: Vec<&str> = Vec::new();
    Ok(())
}

fn proc_from_fzf_output(outputstr: &str) -> Result<proc::Proc, procinfo::ProcError> {
    let pid = if let Some(p) = command::get_pid_from_fzf_output(outputstr) {
        p
    } else {
        return Err(procinfo::ProcError::CustomError(
            "Could not get pid from fzf output".to_owned(),
        ));
    };
    proc::Proc::from_pid(pid)
}

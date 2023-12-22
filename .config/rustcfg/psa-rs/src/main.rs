use std::{env, rc::Rc};
use users;

mod command;
mod options;
mod proc;
mod procinfo;
mod style;

/// Common PIDs of kernel processes (like [kworker/kslavelabor] and [kthreadd])
// const KERNEL_OR_INIT_PIDS: [i32; 3] = [0, 1, 2];

fn main() -> Result<(), procinfo::ProcError> {
    let mut args_iter = env::args().skip(1);
    if let Some(first_arg) = args_iter.next() {
        match first_arg.as_str() {
            "--all" | "-a" => main_process_screen(true)?,
            "--internal-preview-window" => {
                let args = args_iter.collect::<Vec<String>>().join(" ");
                // show_preview_window(&args)?
                show_preview_window_nocache(&args)?
            }
            _ => {
                let help_text = vec![
                    "--all (-a)\tShows all processes, not just those owned by you",
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
        Ok(())
    } else {
        Err(procinfo::ProcError::CustomError(
            "Could not find process!".to_owned(),
        ))
    }
}

/// the real main() function
fn main_process_screen(show_all: bool) -> Result<(), procinfo::ProcError> {
    // make sure I have the required dependencies
    command::check_dependencies(&["fzf", "tput"])?;

    // do this first. If it fails, then I won't have to do more computation.
    let (preview_cmd, preview_cmd_disp) = if let Some(exe) = env::current_exe()?.to_str() {
        (
            format!("--preview={} --internal-preview-window {{}}", exe),
            true,
        )
    } else {
        ("".to_owned(), false)
    };

    let mut user_cache = if show_all {
        procinfo::UserList::all()
    } else {
        procinfo::UserList::just_me()
    };

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
            if !show_all && uid != my_uid {
                return None;
            }
            if let Some(u) = user_cache.get_user(uid) {
                proc::Proc::from_procfs_proc(p, u, &mut style_cache).ok()
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

    // fzf_menu
    let selected_proc = if let Ok(selected_line) = command::fzf_menu(
        console_output.iter(),
        if preview_cmd_disp {
            Some(&preview_cmd)
        } else {
            None
        },
    ) {
        if let Some(sel) = proc_from_fzf_output(&selected_line) {
            Rc::new(sel)
        } else {
            // Don't print an error message if I just hit esc
            return Ok(());
        }
    } else {
        println!("No process selected");
        return Ok(());
    };

    // get a list of the operations I can do on the process
    let capabilities = options::AvailableOptions::get_capabilities(&selected_proc)
        .iter()
        .filter_map(|c| c.describe())
        .map(|c| c.to_owned())
        .collect::<Vec<_>>();

    if let Ok(selected_capability) = command::fzf_menu(capabilities.iter(), None) {
        let action = options::AvailableOptions::from_description(&selected_capability);
        // println!("Selected capability: {:?}", selected_capability);
        action.run_command(Rc::clone(&selected_proc))?;
    }

    Ok(())
}

fn proc_from_fzf_output(outputstr: &str) -> Option<proc::Proc> {
    if let Some(p) = command::get_pid_from_fzf_output(outputstr) {
        if let Ok(proc) = proc::Proc::from_pid(p) {
            return Some(proc);
        }
    }
    None
}

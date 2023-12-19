use serde::{Deserialize, Serialize};
use static_init::{self, dynamic};
use std::{
    collections::HashMap,
    env, error, io,
    path::{Path, PathBuf},
    process,
    rc::Rc,
};
use users;

mod command;
mod proc;
mod style;

const KERNEL_OR_INIT_PPIDS: [i32; 3] = [0, 1, 2];

fn main() -> Result<(), Box<dyn error::Error>> {
    let mut show_all = false;
    for arg in env::args().skip(1) {
        match arg.as_str() {
            "--all" => show_all = true,
            _ => {
                println!("unknown arg: '{}'\nFlag --all will show all processes", arg);
            }
        }
    }
    let user_cache = if show_all {
        proc::UserList::all()
    } else {
        proc::UserList::just_me()
    };
    let preferred_width_base = command::terminal_width()? * 2;

    // let mut color_path_cache: HashMap<&str, Rc<String>> = HashMap::new();
    let mut style_cache = proc::StyleCache::default();
    let my_uid = users::get_current_uid();

    let processes = procfs::process::all_processes()?
        .into_iter()
        .filter_map(|p| p.ok())
        .filter(|p| {
            if show_all {
                true
            } else {
                if let Ok(uid) = p.uid() {
                    !KERNEL_OR_INIT_PPIDS.contains(&p.pid()) && uid == my_uid
                } else {
                    false
                }
            }
        })
        .map(|p| {
            proc::Proc::from_procfs_proc(
                p,
                show_all,
                &user_cache,
                &mut style_cache,
                my_uid,
                preferred_width_base,
            )
        })
        .filter_map(|p| p.ok())
        .collect::<Vec<_>>();

    // println!("Processes: {:#?}", processes);

    for p in processes {
        println!("{}", p.console_style());
    }

    Ok(())
}

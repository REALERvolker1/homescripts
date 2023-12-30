use chrono;
use lscolors;
use nix::{sys::signal, unistd::Pid};
use procfs;
use serde::{Deserialize, Serialize};
use serde_json;
use std::{
    collections::HashMap,
    env,
    error::Error,
    fs,
    io::{self, Write},
    path,
    process::{Command, Stdio},
};

// This may be the least organized rust program I've done yet, but it's not that serious lol

#[derive(Debug, Clone, Copy, PartialEq, Deserialize, Serialize)]
enum FilterType {
    Init,
    Root,
    User,
    OtherUser,
}

#[derive(Debug, Clone, Copy, PartialEq, Deserialize, Serialize)]
enum RecognizedStates {
    Zombie,
    Running,
    Idle,
    Sleeping,
    DiskSleep,
    Unknown,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct UnFmtProcess {
    pid: i32,
    name: String,
    uid: u32,
    state: RecognizedStates,
    filtertype: FilterType,
    is_self: bool,
    args: Vec<String>,
    binary: Option<path::PathBuf>,
    time: String,
    parent_pid: i32,
    fmtpid: String,
    fmtname: String,
    fmtargs: String,
}

const KERNEL_OR_INIT_PPIDS: [i32; 3] = [0, 1, 2];
const ROOT_UID: u32 = 0;
const ARG_COLOR: u8 = 32;

fn main() -> Result<(), Box<dyn Error>> {
    let show_init = false;
    let process_file_string =
        env::var("XDG_RUNTIME_DIR").unwrap_or("/tmp".to_string()) + "/psa.cache";
    let process_file = path::Path::new(&process_file_string);
    let mut args = env::args();
    let argzero = args.next().unwrap();
    if let Some(checkarg) = args.next() {
        if checkarg == "--preview".to_string() {
            // internal arg, not intended for the user to pass
            preview_runtime(process_file, &args.next().unwrap())?;
        } else {
            panic!(
                "{}\nInvalid arg: {}",
                "Error, please run this program without args!", &checkarg
            );
        }
    } else {
        main_runtime(process_file, &argzero, show_init)?;
    }
    Ok(())
}

fn main_runtime(
    process_file: &path::Path,
    argzero: &str,
    show_init: bool,
) -> Result<(), Box<dyn Error>> {
    let processes = get_unformat_procs()?;

    if process_file.exists() {
        fs::remove_file(process_file)?;
    }
    fs::write(process_file, serde_json::to_string(&processes).unwrap())?;

    let proc_fmt_content = processes
        .iter()
        .filter(|i| {
            if show_init {
                return true;
            } else {
                return i.filtertype != FilterType::Init;
            }
        })
        .map(|i| i.to_owned())
        .map(|i| format!("{}\t{}\t{}", i.fmtpid, i.fmtname, i.fmtargs))
        .collect::<Vec<String>>();

    let output = fzf_query(&proc_fmt_content, &format!("{} --preview {{}}", argzero))?;
    let output_process = get_process_from_pid(
        output
            .split_at(output.find("\t").unwrap())
            .0
            .parse::<i32>()
            .unwrap(),
        processes.clone(),
    );
    get_user_option(output_process, processes)?;
    Ok(())
}

fn preview_runtime(process_file: &path::Path, process_string: &str) -> io::Result<()> {
    let process = get_process_from_cache_and_fzfstring(process_string, process_file)?;
    println!("{}", process_preview_string(process));
    Ok(())
}

fn get_user_option(process: UnFmtProcess, all_procs: Vec<UnFmtProcess>) -> io::Result<()> {
    let mut raw_options = vec![(1, "Get statistics"), (2, "Print process tree")];
    let can_kill_procs = process.filtertype == FilterType::User;
    if can_kill_procs {
        raw_options.push((3, "Kill Process"));
    }
    let options = raw_options
        .iter()
        .map(|i| i.0.to_string() + ": " + i.1)
        .collect::<Vec<String>>();

    let preview_string_raw = process_preview_string(process.clone()).replace("'", "`");
    let preview_string = format!("echo '{}\n{}'", "Press ESC to quit", &preview_string_raw);

    let mut user_option = fzf_query(&options, &preview_string)?;
    user_option.truncate(1);
    if user_option.trim().is_empty() {
        panic!("\r\nNo action selected! Exiting...");
    }
    match user_option.as_str() {
        "1" => println!("{}", &preview_string_raw),
        "2" => println!("{}", proc_tree(process, all_procs)),
        "3" => {
            println!("Killing process {}...", process.pid);
            signal::kill(Pid::from_raw(process.pid), signal::SIGKILL).unwrap();
            // let current_process = procfs::process::Process::new(process.pid).unwrap();
        }
        _ => println!("Error, '{}' is not a valid option!", &user_option),
    }

    Ok(())
}

fn proc_tree(main_proc: UnFmtProcess, processes: Vec<UnFmtProcess>) -> String {
    // parents, younger -> older
    let mut parent_procs: Vec<UnFmtProcess> = Vec::new();
    let mut last_proc = main_proc.clone();
    loop {
        let proc = get_process_from_pid(last_proc.parent_pid, processes.clone());
        parent_procs.push(proc.clone());
        if proc.parent_pid == 0 {
            break;
        } else {
            last_proc = proc;
        }
    }
    parent_procs.reverse();

    // children, I want to go only one layer deep because this could get fucky reeeeal quick
    let children = processes
        .iter()
        .filter(|i| &i.parent_pid == &main_proc.pid)
        .map(|i| i.to_owned())
        .collect::<Vec<UnFmtProcess>>();

    // output format with tabs and whatnot lmao
    let mut output = Vec::new();

    output.push(format!(
        "\x1b[0;1m==Process Tree==\n{}\x1b[0m",
        procfs::KernelType::current().unwrap().sysname
    ));

    let mut tabulation = 0;
    for i in parent_procs.iter() {
        output.push(format!(
            "{}\\_({}) {}",
            "  ".repeat(tabulation),
            i.fmtpid,
            i.fmtname
        ));
        tabulation += 1;
    }
    output.push(format!(
        "\x1b[1m{}\\_({}\x1b[1m) {}\x1b[0m",
        "==".repeat(tabulation),
        main_proc.fmtpid,
        main_proc.fmtname
    ));
    tabulation += 1;
    for i in children.iter() {
        output.push(format!(
            "\x1b[2m{}\\_({}) {}",
            "  ".repeat(tabulation),
            i.fmtpid,
            i.fmtname
        ))
    }

    output.join("\n")
}

fn process_preview_string(process: UnFmtProcess) -> String {
    format!(
        "\x1b[0mTIME: \x1b[1;94m{}\x1b[0m\nPID: \x1b[1;93m{}\x1b[0m, NAME: \x1b[1;92m{}\x1b[0m\nState: \x1b[1;96m{:?}\x1b[0m, Command executable: \x1b[1;92m{:?}\x1b[0m\nArgs: {}",
        process.time, process.pid, process.name, process.state, process.binary, process.fmtargs
    )
}

fn fzf_query(selections: &Vec<String>, previewcmd: &str) -> io::Result<String> {
    let preview_command = "--preview=".to_string() + previewcmd;
    let mut selected = Command::new("fzf")
        .args(["--ansi", "--preview-window=down,25%", &preview_command])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;

    let sel_stdin = selected.stdin.as_mut().unwrap();
    for i in selections {
        writeln!(sel_stdin, "{}", i)?;
    }
    let output = selected.wait_with_output()?;
    Ok(String::from_utf8(output.stdout).unwrap())
}

fn get_process_from_cache_and_fzfstring(
    process: &str,
    cachepath: &path::Path,
) -> io::Result<UnFmtProcess> {
    let pid = process
        .split_at(process.find("\t").unwrap())
        .0
        .parse::<i32>()
        .unwrap();
    let process_file_string = fs::read_to_string(cachepath)?;
    let processes: Vec<UnFmtProcess> = serde_json::from_str(&process_file_string)?;
    Ok(get_process_from_pid(pid, processes))
}

fn get_process_from_pid(pid: i32, processes: Vec<UnFmtProcess>) -> UnFmtProcess {
    let myproc_vec = processes
        .iter()
        .filter(|i| i.pid == pid)
        .map(|i| i.to_owned())
        .collect::<Vec<UnFmtProcess>>();

    myproc_vec[0].clone()
}

fn get_unformat_procs() -> procfs::ProcResult<Vec<UnFmtProcess>> {
    let myself = procfs::process::Process::myself()?;
    let my_user = myself.uid()?;
    let my_pid = myself.pid;

    // let rootpath = Path::new("/").to_path_buf();
    let equalfmt = format!("\x1b[{}m=", ARG_COLOR);

    let argfmt_cache: HashMap<String, String> = HashMap::new();

    let mut fmt_processes = Vec::new();
    // let processes: Vec<procfs::process::Process> =
    // .collect();
    let ls_colors = lscolors::LsColors::from_env().unwrap_or_default();

    let current_time = chrono::Local::now().format("%m/%d/%y @ %r").to_string();
    for j in procfs::process::all_processes()? {
        if j.is_err() {
            eprintln!("Encountered unknown process error!");
        }
        let i = j.unwrap();
        let res_status = i.status();
        let res_uid = i.uid();
        if res_status.is_err() || res_uid.is_err() {
            // gracefully fail
            eprintln!("Error gathering statistics for process {}", i.pid);
            continue;
        }
        // we already checked if they were errors
        let status = res_status?;
        let uid = res_uid?;

        let name_color;
        let name = status.name;
        let state;
        match status.state.split_at(status.state.find(" ").unwrap_or(1)).0 {
            "Z" => {
                state = RecognizedStates::Zombie;
                name_color = "1;31";
            }
            "S" => {
                state = RecognizedStates::Sleeping;
                name_color = "93";
            }
            "I" => {
                state = RecognizedStates::Idle;
                name_color = "33";
            }
            "D" => {
                state = RecognizedStates::DiskSleep;
                name_color = "96";
            }
            "R" => {
                state = RecognizedStates::Running;
                name_color = "1;92";
            }
            _ => {
                state = RecognizedStates::Unknown;
                name_color = "35";
            }
        };
        // println!("{} {:?}", status.state, state);

        let mut pid_color;
        let filtertype;

        let parent_pid = status.ppid;

        if uid == my_user {
            filtertype = FilterType::User;
            pid_color = "1;92";
        } else {
            if KERNEL_OR_INIT_PPIDS.contains(&parent_pid) {
                filtertype = FilterType::Init;
                pid_color = "31";
            } else if uid == ROOT_UID {
                filtertype = FilterType::Root;
                pid_color = "1;91";
            } else {
                filtertype = FilterType::OtherUser;
                pid_color = "94";
            }
        }
        if state == RecognizedStates::Zombie {
            pid_color = "31";
        }

        let args = i.cmdline().unwrap_or(Vec::new());
        let mut fmt_args = Vec::new();
        if state == RecognizedStates::Zombie {
            fmt_args.push(String::from("\x1b[1;31m<defunct>\x1b[0m"))
        }

        // needed to color flatpak stuff
        // let root;
        // if let Ok(progroot) = i.root() {
        //     root = progroot;
        // } else {
        //     root = rootpath.clone();
        // }

        // TODO: Clean up, fix some bugs and edge cases, etc etc
        for arcarg in args.iter() {
            for arg in arcarg.split(" ") {
                // fix electron app args
                if let Some(cached_fmt_arg) = argfmt_cache.get(arg) {
                    fmt_args.push(cached_fmt_arg.to_owned())
                } else {
                    let fmt_arg;
                    if arg.contains("/") {
                        if arg.contains("=") {
                            let mut full_arg = Vec::new();
                            for k in arg.split("=") {
                                // let bolded;
                                let kfmt;
                                // let krootpath = root.join(&k);
                                // let kpath = krootpath.as_path();
                                let kpath = path::Path::new(&k);
                                if k.contains("/") && kpath.exists() {
                                    // bolded = "1;";
                                    let mut kvec = Vec::new();
                                    for (component, style) in
                                        ls_colors.style_for_path_components(kpath)
                                    {
                                        if let Some(realstyle) = style {
                                            kvec.push(
                                                realstyle
                                                    .to_nu_ansi_term_style()
                                                    .paint(component.to_string_lossy())
                                                    .to_string(),
                                            )
                                        } else {
                                            kvec.push(format!(
                                                "\x1b[1;{}m{}",
                                                ARG_COLOR,
                                                component.to_string_lossy()
                                            ));
                                        }
                                        // println!("{:?}", &component);
                                    }
                                    kfmt = kvec.join("");
                                } else {
                                    kfmt = format!("\x1b[{}m{}\x1b[0m", ARG_COLOR, k);
                                }
                                full_arg.push(kfmt);
                            }
                            fmt_arg = full_arg.join(&equalfmt);
                        } else if let Some(style) = ls_colors.style_for_path(arg) {
                            fmt_arg = style.to_nu_ansi_term_style().paint(arg).to_string();
                        } else {
                            fmt_arg = format!("\x1b[1;{}m{}\x1b[0m", ARG_COLOR, &arg);
                        }
                    } else {
                        fmt_arg = format!("\x1b[{}m{}\x1b[0m", ARG_COLOR, &arg);
                    }
                    fmt_args.push(fmt_arg)
                }
            }
        }

        fmt_processes.push(UnFmtProcess {
            fmtpid: format!("\x1b[0;{}m{}\x1b[0m", pid_color, i.pid),
            fmtname: format!("\x1b[0;{}m{}\x1b[0m", name_color, &name),
            fmtargs: fmt_args.join(" "),
            pid: i.pid,
            name,
            uid,
            state,
            filtertype,
            is_self: i.pid == my_pid,
            parent_pid,
            args,
            binary: i.exe().ok(),
            time: current_time.clone(),
        });
    }
    Ok(fmt_processes)
}

use std::{
    io,
    env,
};

#[derive(Debug, PartialEq, Clone, Copy)]
pub struct Options {
    error: u32,
    jobs: u32,
    sudo: bool,
    cwd: &'static str,
    init: bool,
    help: bool,
}

// cr --err="$?" --jobs="$(jobs | wc -l)" --sudo="$(sudo -vn &>/dev/null || echo false)"
pub fn parse(args: Vec<String>) -> Result<(), io::Error> {

    let mut error_str: &str = "";
    let mut jobs_str: &str = "";
    let mut sudo_str: &str = "";
    let mut needs_init: bool = false;
    let mut needs_help: bool = false;

    for arg in args.iter() {
        let (key, val) = arg.split_at(arg.find("=").unwrap_or(arg.len() - 1) + 1);
        println!("key: {}, val: {}", &key, &val);
        match key {
            "--err=" => {
                error_str = val
            },
            "--jobs=" => {
                jobs_str = val
            },
            "--sudo=" => {
                sudo_str = val
            },
            "--init" => {
                needs_init = true
            }
            _ => {
                needs_help = true
            }
        }
    }

    if needs_init {
        // stuff
    }
    if needs_help {
        let helptext = vec![
            "vlkprompt-rs possible args:",
            "--err=\"$?\"                                     Specify the error code",
            "--jobs=\"$(jobs | wc -l)\"                       Specify the amount of jobs",
            "--sudo=\"$(sudo -vn &>/dev/null && echo true)\"  Important to copy this in verbatim! Specify sudo perms",
            "--init                                         Set up shell for initialization"
        ];
        println!("{}", helptext.join("\n"));
        panic!("Invalid argument(s) detected")
    }

    let error_num: u32 = error_str.parse::<u32>().unwrap_or(69420);
    let jobs_num: u32 = jobs_str.parse::<u32>().unwrap_or(69420);
    let has_sudo: bool = sudo_str == "true";

    println!("err: {}\njobs: {}\nsudo: {}", error_str, jobs_str, sudo_str);

    let cwd = env::current_dir()?.to_str().unwrap();

    Ok(())
}


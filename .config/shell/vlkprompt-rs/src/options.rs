use std::{
    io,
    fs,
    env,
    error,
};


const OPTIONAL_INT_FALLBACK_U32: u32 = 69420;

#[derive(Debug, PartialEq, Clone)]
pub struct Options {
    has_err: bool,
    error: u32,
    has_jobs: bool,
    jobs: u32,
    has_sudo: bool,
    has_git: bool,
    is_cwd_writable: bool,
    cwd: String,
}

fn get_env(key: &str) -> Result<String, env::VarError> {
    env::var(key)
}
fn get_env_optional_int(key: &str) -> Result<(bool, u32), env::VarError> {
    let env_var = get_env(key)?.parse::<u32>().unwrap_or(OPTIONAL_INT_FALLBACK_U32);
    let env_bool;
    if env_var != 0 {
        env_bool = true;
    }
    else {
        env_bool = false;
    }
    Ok((env_bool, env_var))
}
fn get_env_optional_bool(key: &str) -> Result<bool, env::VarError> {
    let env_var = get_env(key)?;
    Ok(match env_var.as_str() {
        "true" => true,
        _ => false
    })
}

pub fn get_opts() -> Result<Options, Box<dyn error::Error>> {
    let env_err = get_env_optional_int("VLKPROMPT_ERR")?;
    let env_jobs = get_env_optional_int("VLKPROMPT_JOBS")?;
    let env_sudo = get_env_optional_bool("VLKPROMPT_SUDO")?;
    let env_git = get_env_optional_bool("VLKPROMPT_GIT")?;

    let current_dir = env::current_dir()?;
    let writable = fs::metadata(&current_dir)?.permissions().readonly();
    let cwd_string = current_dir.to_string_lossy().replace(&env::var("HOME").unwrap(),"~");
    // let cwd_str = cwd_string.as_ref();

    let opts = Options {
        has_err: env_err.0,
        error: env_err.1,
        has_jobs: env_jobs.0,
        jobs: env_jobs.1,
        has_sudo: env_sudo,
        has_git: env_git,
        is_cwd_writable: writable,
        cwd: cwd_string,
    };
    Ok(opts)
}

// cr --err="$?" --jobs="$(jobs | wc -l)" --sudo="$(sudo -vn &>/dev/null || echo false)"
// pub fn parse() -> Result<Options, io::Error> {

//     let mut error_str: &str = "";
//     let mut jobs_str: &str = "";
//     let mut sudo_str: &str = "";
//     let mut needs_init: bool = false;
//     let mut needs_help: bool = false;

//     for arg in env::args().skip(1) {
//         let (key, val) = arg.split_at(arg.find("=").unwrap_or(arg.len() - 1) + 1);
//         println!("key: {}, val: {}", &key, &val);
//         match key {
//             "--err=" => {
//                 error_str = val
//             },
//             "--jobs=" => {
//                 jobs_str = val
//             },
//             "--sudo=" => {
//                 sudo_str = val
//             },
//             "--init" => {
//                 needs_init = true
//             }
//             _ => {
//                 needs_help = true
//             }
//         }
//     }

//     if needs_init {
//         // stuff
//     }
//     if needs_help {
//         let helptext = vec![
//             "vlkprompt-rs possible args:",
//             "--err=\"$?\"                                     Specify the error code",
//             "--jobs=\"$(jobs | wc -l)\"                       Specify the amount of jobs",
//             "--sudo=\"$(sudo -vn &>/dev/null && echo true)\"  Important to copy this in verbatim! Specify sudo perms",
//             "--init                                         Set up shell for initialization"
//         ];
//         println!("{}", helptext.join("\n"));
//         panic!("Invalid argument(s) detected")
//     }

//     let error_num: u32 = error_str.parse::<u32>().unwrap_or(69420);
//     let jobs_num: u32 = jobs_str.parse::<u32>().unwrap_or(69420);
//     let has_sudo: bool = sudo_str == "true";


//     println!("err: {}\njobs: {}\nsudo: {}", error_str, jobs_str, sudo_str);

//     let cwd = env::current_dir()?.to_str().unwrap();

//     Ok(Options {

//         error
//     })
// }


use std::{
    fs,
    env,
    error,
};

const OPTIONAL_INT_FALLBACK_U32: u32 = 69420;

#[derive(Debug, PartialEq, Clone)]
pub struct Options {
    pub has_err: bool,
    pub error: u32,
    pub has_jobs: bool,
    pub jobs: u32,
    pub has_sudo: bool,
    pub has_git: bool,
    pub has_vim: bool,
    pub is_cwd_writable: bool,
    pub cwd: String,
    pub is_transient: bool,
}

fn get_env_optional_int(key: &str) -> Result<(bool, u32), env::VarError> {
    let env_var = env::var(key)?.parse::<u32>().unwrap_or(OPTIONAL_INT_FALLBACK_U32);
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
    let env_var = env::var(key)?;
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
    let env_vim = get_env_optional_bool("VLKPROMPT_VIM")?;
    let env_transient = get_env_optional_bool("VLKPROMPT_TRANSIENT")?;

    let current_dir = env::current_dir()?;
    let writable = fs::metadata(&current_dir)?.permissions().readonly();
    let cwd_string = current_dir.to_string_lossy().replace(&env::var("HOME").unwrap(),"~");

    let opts = Options {
        has_err: env_err.0,
        error: env_err.1,
        has_jobs: env_jobs.0,
        jobs: env_jobs.1,
        has_sudo: env_sudo,
        has_git: env_git,
        has_vim: env_vim,
        is_cwd_writable: !writable,
        cwd: cwd_string,
        is_transient: env_transient,
    };
    Ok(opts)
}

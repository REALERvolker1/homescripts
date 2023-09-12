use std::{
    io,
    error,
    process,
    env,
};
use serde_json;

pub mod config;
mod options;
mod init;

#[derive(Debug, PartialEq, Clone)]
struct ArgOptions {
    shell: String,
}
fn build_arg_options() -> Result<ArgOptions, io::Error> {
    let mut arg_shell = String::new();
    for arg in env::args().skip(1) {
        if let Some(position) = arg.find("=") {
            let (key, val) = arg.split_at(position + 1);
            match key {
                "--shell=" => arg_shell = val.to_string(),
                _ => continue,
            }
        }
    }
    Ok(ArgOptions {
        shell: arg_shell
    })
}

fn main() -> Result<(), Box<dyn error::Error>> {
    let arg_options = build_arg_options()?;
    let res_opts = options::get_opts();
    let res_config = retrieve_config_leaky();
    if res_config.is_err() || res_opts.is_err() {
        init(arg_options)?;
        process::exit(0)
    }
    let opts = res_opts.unwrap();
    let conf = res_config.unwrap();
    // println!("{}Hello World{}", config.colors.bg_dir_normal, config.colors.sgr);
    // println!("{:#?}", parsed_args);
    Ok(())
}

fn init(arg_options: ArgOptions) -> Result<(), Box<dyn error::Error>> {
    let current_shell = arg_options.shell;
    let config = config::generate_config(&env::var("VLKPROMPT_SHELL").unwrap_or("bash".to_string()))?;
    let json_config = serde_json::to_string(&config)?;
    println!("export VLKPROMPT_CONFIG=\"{}\"", json_config.replace("\"", "\\\""));
    println!("{}", init::INIT_PRECMD_SCRIPT);
    Ok(())
}

fn retrieve_config_leaky() -> Result<config::Config, Box<dyn error::Error>> { // config::Config
    let env_config = env::var("VLKPROMPT_CONFIG").unwrap().leak();
    let myconfig: config::Config = serde_json::from_str(env_config)?;
    Ok(myconfig)
}

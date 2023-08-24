use std::{
    io,
    process,
    env,
};

mod config;
mod argparse;

fn main() -> Result<(), io::Error> {
    let parsed_args = argparse::parse(env::args().skip(1).collect::<Vec<String>>())?;

    let config = config::generate_config()?;
    println!("{}Hello World{}", config.colors.bg_dir_normal, config.colors.sgr);
    println!("{:#?}", parsed_args);
    Ok(())
}



use clap::Parser;
use log::{debug, info, trace, warn};
use std::env;
use tokio;

mod aur;
mod cli;
mod pacman;
mod search;
mod types;

#[tokio::main]
async fn main() -> eyre::Result<()> {
    let args = cli::Args::parse();

    if args.debug {
        env::set_var("RUST_LOG", "debug");
    } else if let Err(_) = env::var("RUST_LOG") {
        // get debug stuff, might remove later
        env::set_var("RUST_LOG", "info");
    }

    env_logger::init();

    debug!("Args received:\n{:?}", args);

    let config = pacman::Config::new(args.show_from.is_alpm(), args.show_from.is_aur())?;

    if let Some(alpm) = config.alpm {
        alpm.set_question_cb(data, f)
    }

    // let aur_handle = raur::Handle::new();
    // aur::aur_search("pacman", &aur_handle).await?;

    println!("Hello, world!");
    Ok(())
}

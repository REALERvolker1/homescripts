use clap::Parser;
use serde::{Deserialize, Serialize};

mod aur;
mod cli;
mod pkg;
mod utils;

fn main() -> eyre::Result<()> {
    let args = cli::Args::parse();
    let cache = pkg::Cache::new(&args.cache_path)?;

    Ok(())
}

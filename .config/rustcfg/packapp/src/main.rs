use std::{env, error::Error};
use tokio;

mod backends;
mod config;
mod db;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // TODO: argparsing or env searching for backend
    let config = config::Config::new().await?;
    println!("{:?}", config.dbfile);

    Ok(())
}

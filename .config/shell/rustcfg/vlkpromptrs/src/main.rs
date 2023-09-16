use std::{
    error::Error,
    env,
    process,
};

mod opts;

fn main() -> Result<(), Box<dyn Error>> {
    opts::generate_config()?;
    Ok(())
}

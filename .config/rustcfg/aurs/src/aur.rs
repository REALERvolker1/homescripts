use crate::*;
pub fn search(args: cli::Args, cache: pkg::Cache) -> eyre::Result<()> {
    let handler = raur::blocking::Handle::new();
    handler.
}

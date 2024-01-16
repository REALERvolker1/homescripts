use crate::{types::*, *};
use clap::Parser;
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};

lazy_static! {
    /// Parse the args as soon as we need them
    pub static ref ARGS: config::Args = config::Args::parse();
}

/// The args for the CLI or binary
#[derive(Parser, Debug, Default, Clone, Deserialize, Serialize)]
#[command(author, version, about, long_about = None, arg_required_else_help(false))]
pub struct Args {
    #[arg(long, short, default_value_t = OutputType::default(), help = "How to format the output")]
    pub output_type: OutputType,
}

use clap::Parser;
use serde::{Deserialize, Serialize};

/// A boolean, but allows for automatic stuff
#[derive(Debug, Default, strum_macros::Display)]
pub enum AutoBool {
    True,
    False,
    #[default]
    Auto,
}

#[derive(Debug, Default, strum_macros::EnumDiscriminants)]
pub enum ModuleConfig {
    Upower {
        /// Enable the module
        enable: AutoBool,
        /// Use this if you are using a charge limit
        charge_limit: bool,
        // TODO: Add support for more backends
        /// Automatically determine the charge limit from asusd, if it exists
        charge_limit_asusd: bool,
    },
    #[default]
    Default
}

// /// The args for the CLI or binary
// #[derive(Parser, Debug, Default, Clone, Deserialize, Serialize)]
// #[command(author, version, about, long_about = None, arg_required_else_help(true))]
// pub struct Args {
//     #[arg(long, short, default_value_t = DisplayType::default(), help = "How to format the output")]
//     pub modules: Vec<String>,
// }

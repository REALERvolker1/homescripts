use clap::Parser;
use serde::{Deserialize, Serialize};
use smart_default::SmartDefault;

/// A boolean, but allows for automatic stuff
#[derive(Debug, Default, strum_macros::Display)]
pub enum AutoBool {
    True,
    False,
    #[default]
    Auto,
}

#[derive(Debug, SmartDefault, strum_macros::EnumDiscriminants, strum_macros::Display)]
pub enum ModuleConfig {
    General {
        /// Set the tempdir preference
        tempdir: Option<String>,
    },
    Upower {
        /// Enable the module
        #[default(AutoBool::default())]
        enable: AutoBool,
        /// Experimental -- alternative upower path
        #[default(Some("/org/freedesktop/UPower/devices/DisplayDevice"))]
        upower_path: Option<String>,
    },
    SuperGfxCtl {
        /// Enable the module
        #[default(AutoBool::default())]
        enable: AutoBool,
    },
    #[default]
    Default,
}

// /// The args for the CLI or binary
// #[derive(Parser, Debug, Default, Clone, Deserialize, Serialize)]
// #[command(author, version, about, long_about = None, arg_required_else_help(true))]
// pub struct Args {
//     #[arg(long, short, default_value_t = DisplayType::default(), help = "How to format the output")]
//     pub modules: Vec<String>,
// }

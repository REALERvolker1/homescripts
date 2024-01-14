use crate::*;
use clap::Parser;
use serde::{Deserialize, Serialize};
use smart_default::SmartDefault;

// /// This is the full config for all the modules.
// ///
// /// TODO: Parse from a config file
// /// TODO: Parse from command line
// #[derive(
//     Debug,
//     SmartDefault,
//     strum_macros::EnumDiscriminants,
//     strum_macros::Display,
//     Serialize,
//     Deserialize,
// )]
// pub enum ModuleConfig {
//     /// General preferences
//     General {
//         /// Set the tempdir preference
//         tempdir: Option<String>,
//     },
//     /// Preferences for the battery module
//     Upower {
//         /// Enable the module
//         #[default(AutoBool::default())]
//         enable: AutoBool,
//         /// Experimental -- alternative upower path
//         #[default(Some("/org/freedesktop/UPower/devices/DisplayDevice"))]
//         upower_path: Option<String>,
//     },
//     /// Preferences for the supergfxctl status module (basically just nvidia optimus but better)
//     /// https://gitlab.com/asus-linux/supergfxctl
//     SuperGfxCtl {
//         /// Enable the module
//         #[default(AutoBool::default())]
//         enable: AutoBool,
//     },
//     Mpris {
//         /// Enable the module
//         #[default(AutoBool::default())]
//         enable: AutoBool,
//         /// Whether to show the artist if available
//         #[default(false)]
//         show_artist: bool,
//         /// Whether to show the album if available
//         #[default(false)]
//         show_album: bool,
//         /// Whether to show the song name if available
//         #[default(true)]
//         show_song: bool,
//     },
//     #[default]
//     None,
// }

// /// The args for the CLI or binary
// #[derive(Parser, Debug, Default, Clone, Deserialize, Serialize)]
// #[command(author, version, about, long_about = None, arg_required_else_help(true))]
// pub struct Args {
//     #[arg(long, short, default_value_t = DisplayType::default(), help = "How to format the output")]
//     pub modules: Vec<String>,
// }

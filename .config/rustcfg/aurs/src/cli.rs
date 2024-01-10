use crate::pkg;
use clap::{Parser, Subcommand, ValueEnum};
use serde::{Deserialize, Serialize};

use strum_macros::{EnumIter, EnumString};

/// The type of transaction to perform
#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    strum_macros::Display,
    EnumString,
    EnumIter,
    Deserialize,
    Serialize,
    ValueEnum,
)]
#[strum(serialize_all = "kebab-case")]
pub enum TransactionType {
    /// Update the database
    Update,
    /// Search the database. If no database exists, it will be created.
    #[default]
    Search,
}

/// Filter out packages you don't want to see
#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    strum_macros::Display,
    EnumString,
    EnumIter,
    Deserialize,
    Serialize,
    ValueEnum,
)]
#[strum(serialize_all = "kebab-case")]
pub enum Filter {
    /// Show all packages
    #[default]
    All,
    /// Only show packages installed
    Installed,
    /// Only show packages that aren't installed
    Available,
    /// Show all, excluding out-of-date packages
    Updated,
}

#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    strum_macros::Display,
    EnumString,
    EnumIter,
    Deserialize,
    Serialize,
    ValueEnum,
)]
#[strum(serialize_all = "kebab-case")]
pub enum DisplayType {
    /// Show all inline
    Inline,
    /// Show as json
    Json,
    /// Show as a terminal table
    #[default]
    Table,
}
// impl Default for DisplayType {
//     fn default() -> Self {
//         // caveman brain way to detect if we're in a tty
//         if env::var("TTY").is_ok() {
//             Self::Table
//         } else {
//             Self::Inline
//         }
//     }
// }

#[derive(Parser, Debug, Default, Clone, Deserialize, Serialize)]
#[command(author, version, about, long_about = None, arg_required_else_help(true))]
pub struct Args {
    // #[arg(long, default_value_t = TransactionType::default(), help = "The type of transaction to perform")]
    // #[arg(long, short, default_value_t = false, help = "Update the databases")]
    // pub update: bool,
    // #[arg(
    //     long,
    //     short,
    //     default_value_t = false,
    //     help = "Search the databases (Will perform an update if no database exists)"
    // )]
    // pub search: bool,
    #[command(subcommand)]
    pub operation: Option<CommandType>,
    #[arg(
        long,
        env = "AURS_CACHE_HOME",
        default_value_t = pkg::Cache::get_default_path(),
        help = "Manually specify the cache folder, create if it doesn't exist."
    )]
    pub cache_path: String,
}

#[derive(Subcommand, Debug, Clone, PartialEq, Eq, EnumIter, Deserialize, Serialize)]
pub enum CommandType {
    Update,
    Search {
        #[arg(long, short, default_value_t = Filter::default(), help = "Filter packages you don't want to see")]
        filter: Filter,
        #[arg(long, short, default_value_t = DisplayType::default(), help = "How to format the output")]
        display_type: DisplayType,
        #[arg(
            trailing_var_arg = true,
            help = "The package names to search for, leave empty to show all"
        )]
        query: Option<Vec<String>>,
    },
}

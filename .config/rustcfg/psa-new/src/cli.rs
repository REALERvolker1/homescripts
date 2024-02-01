use crate::*;
use std::str::FromStr;
use strum::{EnumMessage, IntoEnumIterator};

#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    strum_macros::EnumIter,
    strum_macros::EnumMessage,
    strum_macros::EnumString,
    strum_macros::Display,
)]
#[strum(serialize_all = "lowercase")]
pub enum FilterType {
    #[strum(
        serialize = "--mine",
        serialize = "-m",
        message = "Only show processes created by the current user"
    )]
    Mine,
    #[default]
    #[strum(serialize = "--all", serialize = "-a", message = "Show all processes")]
    All,
    #[strum(
        serialize = "--include-kernel",
        message = "Include kernel processes along with all the others"
    )]
    IncludeKernel,
}

#[derive(Debug, Default)]
pub struct Args {
    pub filter: FilterType,
}
impl Args {
    /// Internally gets all the args passed to the program, returns an Args struct.
    pub fn parse() -> Self {
        let mut args = env::args().skip(1);

        let mut me = Args::default();
        while let Some(arg) = args.next() {
            if let Ok(f) = FilterType::from_str(&arg) {
                me.filter = f;
            } else {
                print_help(&arg)
            }
        }

        me
    }
}

fn print_help(offending_arg: &str) {
    let filter_types = FilterType::iter()
        .map(|f| {
            bold!(f.get_serializations().join(", ")).to_string()
                + "\t"
                + f.get_message().unwrap_or_default()
        })
        .join("\n");

    eprintln!(
        "{}: invalid argument: {}

Available args:
{filter_types}",
        bold!(env!("CARGO_PKG_NAME")),
        bold!(offending_arg),
    );

    std::process::exit(1);
}

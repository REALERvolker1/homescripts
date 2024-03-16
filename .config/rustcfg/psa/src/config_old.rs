use const_format::{concatcp, formatcp, map_ascii_case, Case};
use paste::paste;

use crate::action;

macro_rules! arg {
    ($inp:ident) => {
        concatcp!("--", map_ascii_case!(Case::Kebab, stringify!($inp)))
    };
}

/// tbh I think it would have been smarter to just suck it up and hardcode this myself,
/// but at least I got to learn how paste! works, and I got to brag on discord about this.
macro_rules! cli {
    ($([$name:ident] help: $help:expr, default: $default:expr, $( display_default: $display_default:expr, )? conversion_function: $conversion:tt, type: $ty:ty ),+$(,)?) => {
        /// The part of the config that is taken from the command line arguments
        #[derive(Debug, PartialEq, Eq)]
        pub struct Cli {
            $( pub $name: $ty ),+
        }
        impl Default for Cli {
            fn default() -> Self {
                Self { $( $name: $default ),+ }
            }
        }

        const HELP: &'static str = concatcp!(
            formatcp!("Usage: {} [OPTIONS]\n\n", env!("CARGO_PKG_NAME")),
            $(
                formatcp!("{} <{}> \t {}", arg![$name], stringify!($ty), $help),
                $( formatcp!("\n\t  default: {}", $display_default), )?
                "\n\n",
            )+
            "Run with --help for more information"
        );

        #[allow(non_upper_case_globals)]
        impl Cli {
            pub fn new() -> Self {
                let mut me = Self::default();
                let mut args = std::env::args().skip(1);

                // Match statements can't take output of const_format macros directly. This makes it still const.
                paste! { $( const [<match_str_ $name>]: &str = arg![$name]; )+ }

                while let Some(arg) = args.next() {
                    paste![ match arg.as_str() {
                        $( [<match_str_ $name>] => {
                            if let Some(value) = args.next() {
                                if let Some(computed) = $conversion(value) {
                                    me.$name = computed;
                                } else {
                                    Self::panic_help(arg![$name], "Invalid value");
                                }
                            } else {
                                Self::panic_help(arg![$name], "Missing value");
                            }
                        } )+
                        "--help" => {
                            println!("{HELP}");
                            std::process::exit(0);
                        }
                        _ => Self::panic_help("Invalid argument", &arg),
                    }]
                }

                me
            }
        }
    };
}

// outside of the macro, so I have completions and stuff
impl Cli {
    #[inline]
    pub fn panic_help(arg: &str, error_message: &str) {
        println!("{error_message}: {arg}\n\n{HELP}");
        std::process::exit(2);
    }
}

// implementing the macro

cli! {
    [color]
    help: "Colored output",
    default: true,
    display_default: true,
    conversion_function: string_to_bool,
    type: bool,

    [kernel_procs]
    help: "Show kernel processes along with regular system processes",
    default: false,
    display_default: false,
    conversion_function: string_to_bool,
    type: bool,

    [mine]
    help: "Only show the current user's processes",
    default: false,
    display_default: false,
    conversion_function: string_to_bool,
    type: bool,

    [pipe_command]
    help: "The command to pipe any output to. Should be an fzf-compatible program.",
    default: action::SelectorCommand::default(),
    display_default: action::DEFAULT_SELECTOR_COMMAND_STRING,
    conversion_function: selector_command_from_string,
    type: action::SelectorCommand,

    [format_tab_delimited]
    help: "Tab-delimited pid-name-args, mainly used in the preview window internal function.",
    default: String::default(),
    display_default: "<N/A>",
    conversion_function: bruh,
    type: String
}

/// This is for the preview window
#[inline]
fn bruh(inp: String) -> Option<String> {
    Some(inp)
}

#[inline]
fn selector_command_from_string(inp: String) -> Option<action::SelectorCommand> {
    action::SelectorCommand::new(&inp)
}

#[inline]
fn string_to_bool(inp: String) -> Option<bool> {
    match inp.to_ascii_lowercase().as_str() {
        "true" | "t" | "yes" | "y" | "on" => Some(true),
        "false" | "f" | "no" | "n" | "off" => Some(false),
        _ => None,
    }
}

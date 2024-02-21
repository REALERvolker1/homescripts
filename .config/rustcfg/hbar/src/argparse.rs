use crate::prelude::*;

#[macro_export]
macro_rules! config_struct_nu {
    ($struct_name:tt, $config_struct_name:tt, $($(short: $short:expr,)? default = $default_value:expr, help: $help:expr, long_help: $long_help:expr, $field_name:tt: $field_type:ty),+$(,)?) => {
        #[derive(Debug, Clone, Serialize, Deserialize, SmartDefault)]
        pub struct $struct_name {
            $(
                #[default($default_value)]
                pub $field_name: $field_type,
            )+
        }
        impl crate::config::Configuration for $struct_name {
            type OverwriteWith = $config_struct_name;
            // const SHORT_HELP_VARIANTS: crate::config::HelpVariants = Some(&[
            //     $((const_format::map_ascii_case!(const_format::Case::Kebab, stringify!($field_name)), $help),)+
            // ]);
            config_struct_nu!(SHORT_HELP_VARIANTS, $($field_name, $help,)+);
            config_struct_nu!(LONG_HELP_VARIANTS, $($field_name, $long_help,)+);
            fn overwrite_with(&mut self, overwrite_with: Self::OverwriteWith) {
                $(
                    if let Some(f) = overwrite_with.$field_name {
                        self.$field_name = f
                    }
                )+
            }
            // fn get_help(&self, query: &str) -> &'static str {
            //     for
            // }
        }
        #[derive(Debug, Clone, Serialize, Deserialize, Default)]
        pub struct $config_struct_name {
            $(
                pub $field_name: Option<$field_type>,
            )+
        }
    };
    ($constant:tt, $($field_name:tt, $help_variant:expr),+$(,)?) => {
        const $constant: crate::config::HelpVariants = Some(&[
            $((::const_format::map_ascii_case!(::const_format::Case::Kebab, stringify!($field_name)), $help_variant),)+
        ]);
    };
}

// const fn some_tab(character: Option<char>) -> &'static str {
//     if let Some(c) = character {
//         const_format::concatcp!("\t", character.unwrap())
//     } else {
//         "\t"
//     }
// }

#[derive(Debug, Serialize, Deserialize)]
pub struct ArgumentOption<T>
where
    T: 'static,
{
    pub default: T,
    pub arg_long: &'static str,
    pub arg_short: char,
    pub help_text: &'static str,
}
macro_rules! kebab {
    ($($str:tt),+$(,)?) => {
        ::const_format::map_ascii_case!(::const_format::Case::Kebab, ::const_format::concatcp!($(stringify!($str),)+))
    };
}

macro_rules! args_struct {
    ($([$help_text:expr] $field_name:ident ($arg_short:expr): $default_value_ty:ty = $default_value:expr),+$(,)?) => {
        #[derive(Debug)]
        pub struct Args {
            $(
                pub $field_name: ArgumentOption<$default_value_ty>,
            )+
        }

        impl Default for Args {
            fn default() -> Self {
                Self {
                $(
                    $field_name: ArgumentOption {
                        default: $default_value,
                        arg_long: kebab!($field_name),
                        arg_short: $arg_short,
                        help_text: $help_text,
                    },
                )+
                }
            }
        }
        impl Args {
            pub const fn show_help() -> &'static str {
                ::const_format::concatcp!(
                    $(::const_format::formatcp!(
                        "\x1b[0;1m--{}\x1b[0m (\x1b[0;1m-{}\x1b[0m):\t\x1b[3m{}\x1b[0m",
                        kebab!($field_name), $arg_short, $help_text
                    ),)+
                )
            }
        }
    };
}

args_struct! {
    ["Path to the config file"]
    config_path ('c'): PathBuf = config_path(),

    ["Path to the runtime directory"]
    runtime_path ('r'): PathBuf = runtime_path(),

    ["Log level (for debugging)"]
    log_level ('l'): LogLevel = LogLevel::default(),

    ["Print version"]
    print_version ('V'): () = version(),
}

// const_format::str_index!()
config_struct_nu! {
    ArgConfig, ArgOptions,

    default = config_path(),
    help: "Path to the config file",
    long_help: "Override the path to the config file",
    config_file: PathBuf,
}

pub fn argparse() -> ArgConfig {
    let mut default = ArgConfig::default();
    default
}

macro_rules! home {
    () => {
        dirs::home_dir().expect("Could not find $HOME")
    };
}
// .join(concatcp!(".", NAME))
/// Get the path to the config file. This panics if it can't find any of the other directory
/// options and your `$HOME` variable is not set.
fn config_path() -> PathBuf {
    let path = if let Some(d) = dirs::config_dir() {
        d.join(NAME)
    } else {
        home!().join(concatcp!(".", NAME))
    }
    .join("config.toml");

    debug!("Got default config file path: {}", path.display());
    path
}
/// Get the path to the runtime directory. This panics if it can't find any of the other directory
/// options and your `$HOME` variable is not set.
fn runtime_path() -> PathBuf {
    let path = if let Some(r) = dirs::runtime_dir() {
        r
    } else {
        let temp_dir = env::temp_dir();
        if temp_dir.is_dir() {
            temp_dir
        } else {
            home!().join(".run")
        }
    };

    debug!("Got default runtime dir: {}", path.display());
    path
}

/// Print the version of the application and then exit
fn version() {
    println!("{} v{}", NAME, env!("CARGO_PKG_VERSION"));
    std::process::exit(0);
}

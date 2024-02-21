use crate::prelude::*;
// use smallvec::{SmallVec, ToSmallVec};
// use strum::{EnumMessage, VariantArray};
// use strum_macros;

#[macro_export]
macro_rules! bruh {
    ($error:tt) => {
        return Err($error.into())
    };
}

#[macro_export]
macro_rules! const_kebab {
    ($field:ident) => {
        ::const_format::map_ascii_case!(::const_format::Case::Kebab, stringify!($field))
    };
    (CAPS $field:ident) => {
        ::const_format::map_ascii_case!(::const_format::Case::UpperSnake, stringify!($field))
    };
}

macro_rules! arg_action_enum {
    ($(#[$meta:meta])* $enum:ident {$( $(#[$arg_meta:meta])* [$help:expr] $field:ident ),+$(,)?}) => {
        $(#[$meta])*
        pub enum $enum {
            $(
                $(#[$arg_meta])*
                $field,
            )+
        }
        impl $enum {
            /// The help text to show
            pub const HELP: &'static str = ::const_format::concatcp!(
                NAME, "<OPERATION>\n\n",
                $(
                    "\x1b[1m", const_kebab!($field), "\x1b[0m", "\t", $help, "\n"
                ),+
            );
            /// The number of variants, used for `VARIANTS`
            pub const VARIANT_COUNT: usize = [
                $($enum::$field),+
            ].len();
            /// The variants of this enum
            pub const VARIANTS: [$enum; Self::VARIANT_COUNT] = [
                $($enum::$field),+
            ];
            /// Get this enum as a `&'static str`
            pub const fn str(&self) -> &'static str {
                match self {
                    $(
                        $enum::$field => const_kebab!($field)
                    ),+
                }
            }
        }
        impl ::std::fmt::Display for $enum {
            fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
                write!(f, "{}", self.str())
            }
        }

    };
}

arg_action_enum! {
    #[derive(Debug, Default, Clone, Copy, PartialEq, Eq, ::serde::Serialize, ::serde::Deserialize, strum_macros::EnumString)]
    #[strum(serialize_all = "kebab-case")]
    Operation {
        ["Initialize the shell prompt's environment"]
        Init,
        ["An internal function for the precmd hook"]
        PreCmd,
        ["An internal function for the preexec hook"]
        PreExec,
        ["Show the prompt in all its glory"]
        Display,
        #[default]
        ["Print help"]
        Help,
    }
}

// impl Operation {
//     pub fn act(&self) {
//         match self {
//             Operation::Init => modules::init(),
//             Operation::PreCmd => modules::precmd(),
//             Operation::PreExec => modules::preexec(),
//             Operation::Display => modules::display(),
//             Operation::Help => modules::help(),
//         }
//     }
// }

/// Parses all the args
pub fn parse_arg(argument: Option<String>) -> Operation {
    if let Some(s) = argument {
        Operation::from_str(&s).unwrap_or_default()
    } else {
        Operation::default()
    }
}

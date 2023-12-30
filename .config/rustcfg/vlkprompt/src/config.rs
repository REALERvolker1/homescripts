///! This is the user-facing config file. Edit to make changes.
///!
///! All documentation is in the [configlib.rs](configlib.rs) file as rustdocs.
///! Hover over the variable to see its documentation.
use crate::{configlib::*, format::*};
use lazy_static::lazy_static;

// Helper variables, unnecessary, but helpful for shared config stuff
/// The text color for dark prompt segments (light text on a dark background).
const LIGHT_TXT: u8 = 255;
/// The text color for light prompt segments (dark text on a light background).
const DARK_TXT: u8 = 232;

/// The formatting configuration for the program
pub const FMT_CONFIG: MainFormatConfig = MainFormatConfig {
    cwd: CwdFormatConfig {
        lnk: Format {
            icon: "󰉋",
            text: DARK_TXT,
            color: 51,
        },
        lnk_ro: Format {
            icon: "󱪨",
            text: DARK_TXT,
            color: 51,
        },
        reg: Format {
            icon: "",
            text: LIGHT_TXT,
            color: 33,
        },
        reg_ro: Format {
            icon: "󰉖",
            text: LIGHT_TXT,
            color: 33,
        },
        home: Format {
            icon: "󰋜",
            text: LIGHT_TXT,
            color: 33,
        },
    },
    git: Format {
        icon: "󰊢",
        text: DARK_TXT,
        color: 141,
    },
    vim: Format {
        icon: "",
        text: DARK_TXT,
        color: 120,
    },
    err: Format {
        icon: "󰅗",
        text: LIGHT_TXT,
        color: 52,
    },
    job: Format {
        icon: "󱜯",
        text: DARK_TXT,
        color: 172,
    },
    timer: Format {
        icon: "󱑃",
        text: DARK_TXT,
        color: 226,
    },
    // This is currently unused as I decided to make this a binary instead of a zshmodule
    // env: Format {
    //     icon: "󰫧",
    //     text: LIGHT_TXT,
    //     color: 40,
    // },
    distrobox: Format {
        icon: "󰆍",
        text: LIGHT_TXT,
        color: 96,
    },
    host: Format {
        icon: "󰟀",
        text: LIGHT_TXT,
        color: 18,
    },
    ssh: Format {
        icon: "󰣀",
        text: LIGHT_TXT,
        color: 29,
    },
    login: Format {
        icon: "",
        text: LIGHT_TXT,
        color: 55,
    },
    nix: Format {
        icon: "",
        text: LIGHT_TXT,
        color: 39,
    },
    conda: Format {
        icon: "󱔎",
        text: LIGHT_TXT,
        color: 22,
    },
    venv: Format {
        icon: "",
        text: DARK_TXT,
        color: 220,
    },
    pline_r: PowerlineIconConfig {
        end: "",
        end_special: "",
        separator: "",
        internal_separator: "",
    },
    pline_l: PowerlineIconConfig {
        end: "",
        end_special: " ",
        separator: "",
        internal_separator: "",
    },
};

/// The minimum time in seconds for a command to have run for the
/// Timer segment to show.
pub const MIN_TIME_ELAPSED: usize = 15;

lazy_static! {
    /// The environment variable keys used to configure this at runtime
    pub static ref ENV_CONFIG: EnvConfig = EnvConfig {
        default_hostname: EnvConfigType::get_or_empty("VLKPROMPT_DEFAULT_HOST"),
    };
}

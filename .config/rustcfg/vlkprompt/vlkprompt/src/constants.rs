use lazy_static::lazy_static;
use std::{
    env,
    path::{Path, PathBuf},
};

lazy_static! {
    /// The home directory of the current user. If you don't have this set, your shell is broken.
    pub static ref HOME: PathBuf = PathBuf::from(env::var("HOME").unwrap());
    /// The topmost directories where libgit2 should look for repositories.
    pub static ref GIT_CEILING_DIRS: Vec<PathBuf> = vec![HOME.clone(), PathBuf::from("/")];
}

/// The type I want to have icons in for whatever reason
pub type Icon = &'static str;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Format {
    pub icon: Icon,
    pub text: u8,
    pub color: u8,
}

const LIGHT_TXT: u8 = 255;
const DARK_TXT: u8 = 232;

/// Shared functions for prompt segments that are formatted
pub trait FormatSource {
    fn format(&self) -> Format;
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CwdFormatConfig {
    pub vim: Format,
    pub git: Format,
    pub lnk: Format,
    pub lnk_ro: Format,
    pub reg: Format,
    pub reg_ro: Format,
}

/// The icon config for powerline icons
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PowerlineIconConfig {
    pub end: Icon,
    pub end_special: Icon,
    pub separator: Icon,
    pub internal_separator: Icon,
}

/// The hardcoded formatting configuration
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MainFormatConfig {
    /// Format for the current directory
    pub cwd: CwdFormatConfig,
    /// Format for the error code segment
    pub err: Format,
    /// Format for the jub numbers segment
    pub job: Format,
    /// Format for the timer segment
    pub timer: Format,
    /// Format for the changed environment variable segment 󰫧
    pub env: Format,
    /// Format for the distrobox container segment
    pub distrobox: Format,
    /// If the hostname does not equal `$VLKPROMPT_DEFAULT_HOSTNAME`, this segment is shown
    pub host: Format,
    /// If the shell is a login shell
    pub login: Format,
    /// If you're in a nix environment
    pub nix: Format,
    /// If you're in an anaconda environment. Remember to unset the changeps1 option
    pub conda: Format,
    /// The python venv string
    pub venv: Format,
    /// The powerline icons for the `RPROMPT` <<prompt < foo
    pub pline_r: PowerlineIconConfig,
    /// The powerline config for the regular `PROMPT` foo > PROMPT >>
    pub pline_l: PowerlineIconConfig,
}

pub const FMT_CONFIG: MainFormatConfig = MainFormatConfig {
    cwd: CwdFormatConfig {
        vim: Format {
            icon: "",
            text: DARK_TXT,
            color: 120,
        },
        git: Format {
            icon: "󰊢",
            text: DARK_TXT,
            color: 141,
        },
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
    env: Format {
        icon: "󰫧",
        text: LIGHT_TXT,
        color: 40,
    },
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

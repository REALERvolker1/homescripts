use std::{
    io,
    process,
    env,
};

// #[derive(Debug, PartialEq, Clone, Copy)]
// pub enum IconType {
//     PowerLine,
//     DashLine,
//     FallBack
// }

// I might need to expand this to include ksh or ash
#[derive(Debug, PartialEq, Clone, Copy)]
pub enum Shell {
    Bash,
    Zsh,
}

#[derive(Debug, Clone, Copy)]
pub struct Icons {
    pub git: &'static str,
    pub vim: &'static str,
    pub fs_ro: &'static str,
    pub fs_rw: &'static str,
    pub err: &'static str,
    pub job: &'static str,
    pub end_sudo: &'static str,
    //end: &'static str,
}

#[derive(Debug, Clone, Copy)]
pub struct Colors {
    pub text_light: &'static str,
    pub text_dark: &'static str,
    pub sgr: &'static str,

    pub bg_dir_normal: &'static str,
    pub bg_dir_git: &'static str,
    pub bg_dir_vim: &'static str,
    pub bg_err: &'static str,
    pub bg_job: &'static str,
    pub bg_sudo: &'static str,
    pub bg_ps2: &'static str,
    pub bg_ps3: &'static str,

    pub fg_dir_normal: &'static str,
    pub fg_dir_git: &'static str,
    pub fg_dir_vim: &'static str,
    pub fg_err: &'static str,
    pub fg_job: &'static str,
    pub fg_sudo: &'static str,
    pub fg_ps2: &'static str,
    pub fg_ps3: &'static str,
}

#[derive(Debug, Clone, Copy)]
pub struct Config {
    pub shell: Shell,
    pub icons: Icons,
    pub colors: Colors,
    pub end_icon: &'static str,
}

pub const LOW_COLOR: Colors = Colors {
    text_light: "\x1b[1;37m",
    text_dark: "\x1b[1;30m",
    sgr: "\x1b[0m",

    bg_dir_normal: "\x1b[44m",
    bg_dir_git: "\x1b[45m",
    bg_dir_vim: "\x1b[42m",
    bg_err: "\x1b[41m",
    bg_job: "\x1b[43m",
    bg_sudo: "\x1b[46m",
    bg_ps2: "\x1b[45m",
    bg_ps3: "\x1b[45m",

    fg_dir_normal: "\x1b[34m",
    fg_dir_git: "\x1b[35m",
    fg_dir_vim: "\x1b[32m",
    fg_err: "\x1b[31m",
    fg_job: "\x1b[33m",
    fg_sudo: "\x1b[36m",
    fg_ps2: "\x1b[35m",
    fg_ps3: "\x1b[35m",
};

pub const HIGH_COLOR: Colors = Colors {
    text_light: "\x1b[1;38;5;255m",
    text_dark: "\x1b[1;38;5;232m",
    sgr: "\x1b[0m",

    bg_dir_normal: "\x1b[48;5;33m",
    bg_dir_git: "\x1b[48;5;141m",
    bg_dir_vim: "\x1b[48;5;120m",
    bg_err: "\x1b[48;5;52m",
    bg_job: "\x1b[48;5;172m",
    bg_sudo: "\x1b[48;5;196m",
    bg_ps2: "\x1b[48;5;93m",
    bg_ps3: "\x1b[48;5;95m",

    fg_dir_normal: "\x1b[38;5;33m",
    fg_dir_git: "\x1b[38;5;141m",
    fg_dir_vim: "\x1b[38;5;120m",
    fg_err: "\x1b[38;5;52m",
    fg_job: "\x1b[38;5;172m",
    fg_sudo: "\x1b[38;5;196m",
    fg_ps2: "\x1b[38;5;93m",
    fg_ps3: "\x1b[38;5;95m",
};

pub const FANCY_ICONS: Icons = Icons {
    git: "󰊢",
    vim: "",
    fs_ro: "",
    fs_rw: "",
    err: "󰅗",
    job: "󱜯",
    end_sudo: "",
};

pub const ASCII_ICONS: Icons = Icons {
    git: "G",
    vim: "V",
    fs_ro: "-",
    fs_rw: ".",
    err: "X",
    job: "J",
    end_sudo: "#",
};

pub fn generate_config() -> Result<Config, io::Error> {

    let shell = match env::var("VLKPROMPT_SHELL").unwrap_or("bash".to_string()).as_str() {
        "zsh" => Shell::Zsh,
        "bash" => Shell::Bash,
        _ => Shell::Bash,
    };

    let raw_icon_type = env::var("ICON_TYPE").unwrap_or("fallback".to_string());

    let end_icon: &str;
    let icons: Icons;
    match raw_icon_type.to_lowercase().as_str() {
        "powerline" => {
            end_icon = "";
            icons = FANCY_ICONS;
        },
        "dashline" => {
            end_icon = "";
            icons = FANCY_ICONS;
        },
        _ => {
            end_icon = "]";
            icons = ASCII_ICONS;
        }
    };

    let color_override = env::var("VLKPROMPT_COLOR_OVERRIDE").unwrap_or("".to_string());
    let color_amount: u32;

    if color_override.is_empty() {
        let tput_proc = process::Command::new("tput")
            .arg("colors")
            .output()?;

        if tput_proc.status.success() {
            let stdout_str = String::from_utf8(tput_proc.stdout).unwrap_or("0".to_string());
            color_amount = stdout_str.trim_end().parse::<u32>().unwrap_or(0);
        } else {
            eprintln!("Error running tput:\n{:#?}", tput_proc);
            color_amount = 0
        }
    } else {
        color_amount = color_override.parse::<u32>().unwrap_or(0);
    }

    let colors: Colors;
    if color_amount < 256 {
        colors = LOW_COLOR;
    } else {
        colors = HIGH_COLOR;
    }

    Ok(Config {
        shell: shell,
        icons: icons,
        colors: colors,
        end_icon: end_icon,
    })
}

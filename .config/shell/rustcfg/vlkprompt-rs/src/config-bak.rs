use std::{
    io,
    process,
    env,
};
use serde::{Serialize, Deserialize};

// #[derive(Debug, PartialEq, Clone, Copy)]
// pub enum IconType {
//     PowerLine,
//     DashLine,
//     FallBack
// }

// I might need to expand this to include ksh or ash
#[derive(Serialize, Deserialize, Debug, PartialEq, Clone, Copy)]
pub enum Shell {
    Bash,
    Zsh,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Icons {
    pub git: String,
    pub vim: String,
    pub fs_ro: String,
    pub fs_rw: String,
    pub err: String,
    pub job: String,
    pub end_sud: String,
}
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Colors {
    pub dir: String,
    pub git: String,
    pub vim: String,
    pub err: String,
    pub job: String,
    pub sud: String,
    pub ps2: String,
    pub ps3: String,
}


#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ColorScheme {
    pub text_light: String,
    pub text_dark: String,
    pub sgr: String,

    pub background: Colors,
    pub foreground: Colors,
}
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Config {
    pub shell: Shell,
    pub icons: Icons,
    pub colors: ColorScheme,
    pub end_icon: String,
}

macro_rules! color {
    ($i:expr) => {
        format!("\x1b[{}m", $i)
    }
}

macro_rules! fancy_icons {
    () => {
        Icons {
            git: "󰊢".to_string(),
            vim: "".to_string(),
            fs_ro: "".to_string(),
            fs_rw: "".to_string(),
            err: "󰅗".to_string(),
            job: "󱜯".to_string(),
            end_sud: "".to_string(),
        }
    };
}
macro_rules! ascii_icons {
    () => {
        Icons {
            git: "G".to_string(),
            vim: "V".to_string(),
            fs_ro: "-".to_string(),
            fs_rw: ".".to_string(),
            err: "X".to_string(),
            job: "J".to_string(),
            end_sud: "#".to_string(),
        }
    };
}
macro_rules! low_color {
    () => {
        ColorScheme {
            text_light: color!("1;37"),
            text_dark: color!("1;30"),
            sgr: color!("0"),
            background: Colors {
                dir: color!("44"),
                git: color!("45"),
                vim: color!("42"),
                err: color!("41"),
                job: color!("43"),
                sud: color!("46"),
                ps2: color!("45"),
                ps3: color!("45"),
            },
            foreground: Colors {
                dir: color!("34"),
                git: color!("35"),
                vim: color!("32"),
                err: color!("31"),
                job: color!("33"),
                sud: color!("36"),
                ps2: color!("35"),
                ps3: color!("35"),
            }
        }
    };
}
macro_rules! high_color {
    () => {
        ColorScheme {
            text_light: color!("1;38;5;255"),
            text_dark: color!("1;38;5;232"),
            sgr: color!("0"),
            background: Colors {
                dir: color!("48;5;33"),
                git: color!("48;5;141"),
                vim: color!("48;5;120"),
                err: color!("48;5;52"),
                job: color!("48;5;172"),
                sud: color!("48;5;196"),
                ps2: color!("48;5;93"),
                ps3: color!("48;5;95"),
            },
            foreground: Colors {
                dir: color!("38;5;33"),
                git: color!("38;5;141"),
                vim: color!("38;5;120"),
                err: color!("38;5;52"),
                job: color!("38;5;172"),
                sud: color!("38;5;196"),
                ps2: color!("38;5;93"),
                ps3: color!("38;5;95"),
            }
        }
    };
}


pub fn generate_config(current_shell: &str) -> Result<Config, io::Error> {
    let shell = match current_shell.to_ascii_lowercase().as_str() {
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
            icons = fancy_icons!();
        },
        "dashline" => {
            end_icon = "";
            icons = fancy_icons!();
        },
        _ => {
            end_icon = "]";
            icons = ascii_icons!();
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

    let colors: ColorScheme;
    if color_amount < 256 {
        colors = low_color!();
    } else {
        colors = high_color!();
    }

    Ok(Config {
        shell: shell,
        icons: icons,
        colors: colors,
        end_icon: end_icon.to_string(),
    })
}

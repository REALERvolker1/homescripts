use std::{
    io,
    process,
    error,
    env,
    fs
};
use serde::{Serialize, Deserialize};

// I might need to expand this to include ksh or ash
#[derive(Serialize, Deserialize, Debug, PartialEq, Clone, Copy)]
pub enum Shell {
    Bash,
    Zsh,
}
#[derive(Serialize, Deserialize, Debug, PartialEq, Clone, Copy)]
pub enum DirType {
    Cwd,
    Git,
    Vim,
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
#[derive(Debug, PartialEq, Clone)]
pub struct Options {
    pub has_err: bool,
    pub error: u32,
    pub has_jobs: bool,
    pub jobs: u32,
    pub has_sudo: bool,
    pub cwd_type: DirType,
    pub is_cwd_writable: bool,
    pub cwd: String,
    pub is_transient: bool,
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

fn get_env_optional_int(key: &str) -> Result<(bool, u32), env::VarError> {
    let env_var = env::var(key)?.parse::<u32>().unwrap_or(69420); // magic number that is big enough for you to notice
    let env_bool;
    if env_var != 0 {
        env_bool = true;
    }
    else {
        env_bool = false;
    }
    Ok((env_bool, env_var))
}
fn get_env_optional_bool(key: &str) -> Result<bool, env::VarError> {
    let env_var = env::var(key)?;
    Ok(match env_var.as_str() {
        "true" => true,
        _ => false
    })
}

pub fn get_opts() -> Result<Options, Box<dyn error::Error>> {
    let env_err = get_env_optional_int("VLKPROMPT_ERR")?;
    let env_jobs = get_env_optional_int("VLKPROMPT_JOBS")?;
    let env_sudo = get_env_optional_bool("VLKPROMPT_SUDO")?;
    let env_transient = get_env_optional_bool("VLKPROMPT_TRANSIENT")?;

    let env_type;
    if get_env_optional_bool("VLKPROMPT_VIM")? {
        env_type = DirType::Vim
    }
    else if get_env_optional_bool("VLKPROMPT_GIT")? {
        env_type = DirType::Git
    }
    else {
        env_type = DirType::Cwd
    }

    let current_dir = env::current_dir()?;
    let writable = fs::metadata(&current_dir)?.permissions().readonly();
    let cwd_string = current_dir.to_string_lossy().replace(&env::var("HOME").unwrap(),"~");

    let opts = Options {
        has_err: env_err.0,
        error: env_err.1,
        has_jobs: env_jobs.0,
        jobs: env_jobs.1,
        has_sudo: env_sudo,
        cwd_type: env_type,
        is_cwd_writable: !writable,
        cwd: cwd_string,
        is_transient: env_transient,
    };
    Ok(opts)
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct DefinedConfig {
    pub err: String,
    pub err_job: String,
    pub err_dir: String,
    pub job: String,
    pub job_dir: String,
    pub dir: String,
    pub dir_end: String,
    pub dir_sud: String,
}
pub fn define_config(cfg: Config, opt: Options) -> Result<DefinedConfig, Box<dyn error::Error>> {

    let dir_bg;
    let dir_fg;
    let dir_text;
    let dir_icon;
    match opt.cwd_type {
        DirType::Cwd => {
            dir_bg = &cfg.colors.background.dir;
            dir_fg = &cfg.colors.foreground.dir;
            dir_text = &cfg.colors.text_light;
            if &opt.is_cwd_writable == &true {
                dir_icon = &cfg.icons.fs_rw
            } else {
                dir_icon = &cfg.icons.fs_ro
            }
        },
        DirType::Git => {
            dir_bg = &cfg.colors.background.git;
            dir_fg = &cfg.colors.foreground.git;
            dir_text = &cfg.colors.text_dark;
            dir_icon = &cfg.icons.git;
        },
        DirType::Vim => {
            dir_bg = &cfg.colors.background.vim;
            dir_fg = &cfg.colors.foreground.vim;
            dir_text = &cfg.colors.text_dark;
            dir_icon = &cfg.icons.vim;
        }
    }
    let def_conf = DefinedConfig {
        err: format!("{}{}{} {} {} {}",
            &cfg.colors.sgr,
            &cfg.colors.background.err,
            &cfg.colors.text_light,
            &cfg.icons.err,
            &opt.error,
            &cfg.colors.sgr
        ),
        err_job: format!("{}{}{}{}{}",
            &cfg.colors.sgr,
            &cfg.colors.foreground.err,
            &cfg.colors.background.job,
            &cfg.end_icon,
            &cfg.colors.sgr
        ),
        err_dir: format!("{}{}{}{}{}",
            &cfg.colors.sgr,
            &cfg.colors.foreground.err,
            &dir_bg,
            &cfg.end_icon,
            &cfg.colors.sgr
        ),

        job: format!("{}{}{} {} {} {}",
            &cfg.colors.sgr,
            &cfg.colors.background.job,
            &cfg.colors.text_dark,
            &cfg.icons.job,
            &opt.jobs,
            &cfg.colors.sgr
        ),
        job_dir: format!("{}{}{}{}{}",
            &cfg.colors.sgr,
            &cfg.colors.foreground.job,
            &dir_bg,
            &cfg.end_icon,
            &cfg.colors.sgr
        ),

        dir: format!("{}{}{} {} {} {}",
            &cfg.colors.sgr,
            &dir_bg,
            &dir_text,
            &dir_icon,
            &opt.cwd,
            &cfg.colors.sgr
        ),
        dir_end: format!("{}{}{}{}",
            &cfg.colors.sgr,
            &dir_fg,
            &cfg.end_icon,
            &cfg.colors.sgr
        ),
        dir_sud: format!("{}{}{}{} {}{}{}{} ",
            &cfg.colors.sgr,
            &dir_fg,
            &cfg.colors.background.sud,
            cfg.end_icon,
            &cfg.colors.sgr,
            &cfg.colors.foreground.sud,
            &cfg.icons.end_sud,
            &cfg.colors.sgr
        )
    };
    Ok(def_conf)
}

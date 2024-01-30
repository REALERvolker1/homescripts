use std::env;

pub type Icon = char;

macro_rules! icon {
    ($var:expr, $default:expr) => {
        if let Ok(icn) = env::var($var) {
            icn.chars().next().unwrap_or($default)
        } else {
            $default
        }
    };
}
macro_rules! color {
    ($var:expr, $default:expr) => {
        if let Ok(color) = env::var($var) {
            color.parse().unwrap_or($default)
        } else {
            $default
        }
    };
}

// fn colofr(var: &str, default: u8) -> u8 {
//     if let Ok(color) = env::var(var) {
//         color.parse().unwrap_or(default)
//     } else {
//         default
//     }
// }

fn get_value(key: &str) -> Option<String> {
    env::var(key).ok()
}

pub const DARK_TEXT: u8 = 232;
pub const LIGHT_TEXT: u8 = 255;

pub const LOGIN_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_LOGIN_ICON",
    default_icon: '󰌆',
    color_var: "VLKPROMPT_LOGIN_COLOR",
    default_color: 55,
    text_color_var: "VLKPROMPT_LOGIN_TEXT_COLOR",
    default_text_color: LIGHT_TEXT,
    value_var: "VLKPROMPT_LOGIN",
    default_value: None,
};

pub const HOSTNAME_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_HOSTNAME_ICON",
    default_icon: '󰟀',
    color_var: "VLKPROMPT_HOSTNAME_COLOR",
    default_color: 18,
    text_color_var: "VLKPROMPT_HOSTNAME_TEXT_COLOR",
    default_text_color: LIGHT_TEXT,
    value_var: "VLKPROMPT_HOSTNAME",
    default_value: None,
};

pub const DISTROBOX_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_DISTROBOX_ICON",
    default_icon: '󰌆',
    color_var: "VLKPROMPT_DISTROBOX_COLOR",
    default_color: 95,
    text_color_var: "VLKPROMPT_DISTROBOX_TEXT_COLOR",
    default_text_color: LIGHT_TEXT,
    value_var: "VLKPROMPT_DISTROBOX",
    default_value: None,
};

pub const CONDA_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_CONDA_ICON",
    default_icon: '󱔎',
    color_var: "VLKPROMPT_CONDA_COLOR",
    default_color: 40,
    text_color_var: "VLKPROMPT_CONDA_TEXT_COLOR",
    default_text_color: DARK_TEXT,
    value_var: "VLKPROMPT_CONDA",
    default_value: None,
};

pub const VENV_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_VENV_ICON",
    default_icon: '󰌠',
    color_var: "VLKPROMPT_VENV_COLOR",
    default_color: 220,
    text_color_var: "VLKPROMPT_VENV_TEXT_COLOR",
    default_text_color: DARK_TEXT,
    value_var: "VLKPROMPT_VENV",
    default_value: None,
};

pub const TIME_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_TIME_ICON",
    default_icon: '󰌠',
    color_var: "VLKPROMPT_TIME_COLOR",
    default_color: 220,
    text_color_var: "VLKPROMPT_TIME_TEXT_COLOR",
    default_text_color: DARK_TEXT,
    value_var: "VLKPROMPT_TIME",
    default_value: None,
};

pub const JOB_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_JOB_ICON",
    default_icon: '󰌆',
    color_var: "VLKPROMPT_JOB_COLOR",
    default_color: 0,
    text_color_var: "VLKPROMPT_JOB_TEXT_COLOR",
    default_text_color: 0,
    value_var: "VLKPROMPT_JOB",
    default_value: None,
};

pub const ERROR_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_ERROR_ICON",
    default_icon: '󰌆',
    color_var: "VLKPROMPT_ERROR_COLOR",
    default_color: 0,
    text_color_var: "VLKPROMPT_ERROR_TEXT_COLOR",
    default_text_color: 0,
    value_var: "VLKPROMPT_ERROR",
    default_value: None,
};

pub const PWD_LINK_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "ENV_PWD_LINK_ICON",
    default_icon: '󰌆',
    color_var: "ENV_PWD_LINK_COLOR",
    default_color: 0,
    text_color_var: "ENV_PWD_LINK_TEXT_COLOR",
    default_text_color: 0,
    value_var: "ENV_PWD_LINK",
    default_value: None,
};

pub const PWD_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "ENV_PWD_ICON",
    default_icon: '󰌆',
    color_var: "ENV_PWD_COLOR",
    default_color: 0,
    text_color_var: "ENV_PWD_TEXT_COLOR",
    default_text_color: 0,
    value_var: "ENV_PWD",
    default_value: None,
};

pub const VIM_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "ENV_VIM_ICON",
    default_icon: '󰌆',
    color_var: "ENV_VIM_COLOR",
    default_color: 0,
    text_color_var: "ENV_VIM_TEXT_COLOR",
    default_text_color: 0,
    value_var: "ENV_VIM",
    default_value: None,
};

pub const GIT_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "ENV_GIT_ICON",
    default_icon: '󰌆',
    color_var: "ENV_GIT_COLOR",
    default_color: 0,
    text_color_var: "ENV_GIT_TEXT_COLOR",
    default_text_color: 0,
    value_var: "ENV_GIT",
    default_value: None,
};

pub const SUDO_BUILDER: BlockBuilder = BlockBuilder {
    icon_var: "VLKPROMPT_SUDO_ICON",
    default_icon: '󰌆',
    color_var: "VLKPROMPT_SUDO_COLOR",
    default_color: 0,
    text_color_var: "VLKPROMPT_SUDO_TEXT_COLOR",
    default_text_color: 0,
    value_var: "VLKPROMPT_SUDO",
    default_value: None,
};

pub struct BlockBuilder {
    pub icon_var: &'static str,
    pub default_icon: Icon,
    pub color_var: &'static str,
    pub default_color: u8,
    pub text_color_var: &'static str,
    pub default_text_color: u8,
    pub value_var: &'static str,
    pub default_value: Option<String>,
}

/// The individual segment settings
pub struct Block {
    pub icon: Icon,
    pub color: u8,
    pub is_light_text: bool,
    pub value: String,
}

// fn login_block() -> Block {
//     let login_icon = icon!(ENV_LOGIN_ICON, '󰌆');
// }

pub struct BlockConfig {
    pub login: Option<Block>,
    pub hostname: Option<Block>,
    pub distrobox: Option<Block>,
    pub conda: Option<Block>,
    pub venv: Option<Block>,
    pub job: Option<Block>,
    pub error: Option<Block>,
    pub pwd_vim: Option<Block>,
    pub pwd_git: Option<Block>,
    pub pwd_link: Option<Block>,
    pub pwd: Option<Block>,
    pub sudo: Option<Block>,
}
// impl BlockConfig {
//     pub fn new() -> () {
//         let login_block = if env::var(ENV_LOGIN).is_ok() {}
//     }
// }

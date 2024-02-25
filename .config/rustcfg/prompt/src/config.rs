use crate::modules::*;
use crate::prelude::*;

/// The config. It is updated on precmd, and retrieved when the program is first run. This must be very fast to parse, so I am using simd and stuff.
#[derive(Debug, Default, Serialize, Deserialize)]
pub struct PrecmdConfig {
    pub cwd: cwd::Cwd,
    pub job: usize,
    pub err: usize,
    pub has_sudo: bool,
}
impl PrecmdConfig {
    pub fn parse() -> R<Self> {
        let mut variable_content = env::var(CONFIG_VAR)?;
        unsafe { simd_json::from_slice(variable_content.as_bytes_mut()) }.map_err(|e| e.into())
    }
    pub fn export_self(&self) -> simd_json::Result<()> {
        let me = simd_json::to_string(self)?;
        // make this safe to eval in the shell as a scalar literal
        let sanitized_me = me.replace("'", "'\\''");

        // TODO: Implement for setting the variable for zsh-modules as well
        println!("export {CONFIG_VAR}='{sanitized_me}'");
        Ok(())
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct BlockConfig {
    pub icon: char,
    pub color: Color,
    pub text_color: Color,
}
impl BlockConfig {
    pub const fn block(icon: char, color: u8, is_light_text: bool) -> Self {
        Self {
            icon,
            color: Color::Fixed(color),
            text_color: if is_light_text { LIGHT_TXT } else { DARK_TXT },
        }
    }
}

// These are some settings that I am making const for performance

pub const LEFT_SEPARATOR: char = '';
pub const RGHT_SEPARATOR: char = '';

/// The text color for dark prompt segments (light text on a dark background).
const LIGHT_TXT: Color = Color::Fixed(255);
/// The text color for light prompt segments (dark text on a light background).
const DARK_TXT: Color = Color::Fixed(232);

pub const GIT_BLOCK: BlockConfig = BlockConfig::block('󰊢', 141, false);
pub const VIM_BLOCK: BlockConfig = BlockConfig::block('', 120, false);
pub const ERR_BLOCK: BlockConfig = BlockConfig::block('󰅗', 52, true);
pub const JOB_BLOCK: BlockConfig = BlockConfig::block('󱜯', 172, true);
pub const TIM_BLOCK: BlockConfig = BlockConfig::block('󱑃', 226, true);
pub const HOS_BLOCK: BlockConfig = BlockConfig::block('󰟀', 18, true);
pub const LOG_BLOCK: BlockConfig = BlockConfig::block('󰌆', 55, true);

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

// These are some settings that I am making const for performance

pub const LEFT_END: char = '';

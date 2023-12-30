use crate::{config, configlib, prompt};

/// Show if the user is in a login shell or not. It is added to the global state if the user is in a login shell.
#[derive(Debug, Clone)]
pub struct Login;
impl prompt::Module for Login {
    fn format(&self) -> configlib::Format {
        config::FMT_CONFIG.login
    }
    fn should_show(&self) -> bool {
        true
    }
}

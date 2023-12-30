use std::env;
use zsh_module;

#[derive(Default, Clone, Debug)]
pub struct Timer {
    pub prev: usize,
    pub hours: usize,
    pub minutes: usize,
    pub seconds: usize,
}
impl Timer {
    fn get_seconds_from_env() -> usize {
        if let Ok(s) = env::var("SECONDS") {
            if let Ok(p) = s.parse() {
                return p;
            }
        }
        0
    }
    pub fn start() -> Self {
        Self {
            prev: Self::get_seconds_from_env(),
            hours: 0,
            minutes: 0,
            seconds: 0,
        }
    }
    pub fn measure(&mut self) {
        let now = Self::get_seconds_from_env();
        self.hours = now / 3600;
        self.minutes = (now % 3600) / 60;
        self.seconds = now % 60;
    }
}

use crate::{config, configlib, prompt, format};
use std::{
    env,
    path::{Path, PathBuf},
};

/// A struct to determine how long a command took to run.
#[derive(Default, Clone, Debug)]
pub struct Timer {
    /// The time in seconds before the command started.
    pub prev: usize,
    /// The difference in seconds between the previous time and the current time.
    pub elapsed: usize,
    pub hours: usize,
    pub minutes: usize,
    pub seconds: usize,
}
impl Timer {
    pub fn start(current_time: usize) -> Self {
        Self {
            prev: current_time,
            elapsed: 0,
            hours: 0,
            minutes: 0,
            seconds: 0,
        }
    }
    pub fn stop(&mut self, current_time: usize) {
        self.elapsed = current_time - self.prev;
        self.hours = current_time / 3600;
        self.minutes = (current_time % 3600) / 60;
        self.seconds = current_time % 60;
    }
}
impl prompt::DynamicModule for Timer {
    fn update(&mut self, update_type: prompt::UpdateType) -> prompt::UpdateResult<()> {
        prompt::UpdateResult::Ok(())
    }
}
impl prompt::Module for Timer {
    fn format(&self) -> format::Format {
        config::FMT_CONFIG.timer
    }
    fn should_show(&self) -> bool {
        self.elapsed > config::MIN_TIME_ELAPSED
    }
}

pub mod cpu;
pub mod disks;
pub mod memory;

use crate::*;
use size::Size;
use sysinfo::{Disks, System};
const DEFAULT_DISK_POLL_RATE: Duration = Duration::from_secs(60 * 2);

/// TODO: Maybe break up
#[derive(Debug, Clone, Copy, SmartDefault, Deserialize, Serialize)]
pub struct SystemInfoConfig {
    #[default = true]
    pub show_memory: bool,
    #[default(FIVE_SECONDS)]
    pub memory_poll_rate: Duration,
    #[default = true]
    pub show_cpu: bool,
    #[default(FIVE_SECONDS)]
    pub cpu_poll_rate: Duration,
    #[default = true]
    pub show_disks: bool,
    #[default(DEFAULT_DISK_POLL_RATE)]
    pub disks_poll_rate: Duration,
}

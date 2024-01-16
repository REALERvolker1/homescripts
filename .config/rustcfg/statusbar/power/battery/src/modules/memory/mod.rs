use core::fmt;

use super::*;
use crate::config;
// use crate::types::*;
use serde::{Deserialize, Serialize};
use size::Size;
use sysinfo::{MemoryRefreshKind, RefreshKind};
use tracing::{debug, error, warn};

/// TODO: Read from config
pub const MEM_POLL_RATE: std::time::Duration = std::time::Duration::from_secs(15);

pub struct MemoryModule {
    poll_rate: std::time::Duration,
    info: sysinfo::System,
    refresh_swap: bool,
    mem: Memory,
    swap: Option<Memory>,
}
impl StaticModule for MemoryModule {
    fn mod_type(&self) -> ModuleType {
        ModuleType::Poll
    }
    fn name(&self) -> &str {
        "memory"
    }
    async fn update_server(&self, ipc: &IpcCh) -> ModResult<()> {
        ipc.send(StateType::Memory(
            self.with_output_type(config::ARGS.output_type),
        ))
        .await?;
        Ok(())
    }
}
impl Module for MemoryModule {
    fn should_run(&self) -> bool {
        true
    }
    #[tracing::instrument(skip(self))]
    async fn update(&mut self, payload: RecvType) -> ModResult<()> {
        self.info.refresh_memory();
        if let Some(m) = Memory::new_from_mem_sysinfo(&self.info) {
            self.mem = m
        } else {
            error!("Failed to get memory info!");
            return Err(ModError::Other("Failed to get memory info".into()));
        }
        if self.refresh_swap {
            self.swap = Memory::new_from_swap_sysinfo(&self.info);
        }
        Ok(())
    }
    #[tracing::instrument(skip(self, ipc))]
    async fn run(&mut self, ipc: IpcCh) -> ModResult<()> {
        loop {
            if let Err(e) = self.update(RecvType::Null).await {
                error!("{e}");
            } else {
                self.update_server(&ipc).await?;
            }
            tokio::time::sleep(self.poll_rate).await;
        }
    }
}
impl PollModule for MemoryModule {
    #[tracing::instrument]
    async fn new(poll_rate: std::time::Duration) -> ModResult<Self> {
        // TODO: Read config
        const USE_SWAP: bool = true;

        let refresh_kind = RefreshKind::new().with_memory(if USE_SWAP {
            MemoryRefreshKind::everything()
        } else {
            MemoryRefreshKind::new().with_ram()
        });
        let info = sysinfo::System::new_with_specifics(refresh_kind);

        let swap = if USE_SWAP {
            Memory::new_from_swap_sysinfo(&info)
        } else {
            None
        };
        let mem = if let Some(m) = Memory::new_from_mem_sysinfo(&info) {
            m
        } else {
            return Err(ModError::Other("Failed to get memory info".into()));
        };
        Ok(Self {
            poll_rate,
            info,
            refresh_swap: USE_SWAP,
            mem,
            swap,
        })
    }
}
impl FmtModule for MemoryModule {
    fn stdout(&self) -> String {
        if let Some(s) = self.swap {
            // format!("{MEMORY_ICON} {} {}", self.mem.usage, s.usage)
            format!("{MEMORY_ICON} {} {}", self.mem.used, s.usage)
        } else {
            format!("{MEMORY_ICON} {}", self.mem.used)
        }
    }
    fn waybar(&self) -> String {
        let text = self.stdout();
        let details = if let Some(s) = self.swap {
            format!("Memory\n{}\nSwap\n{}", self.mem, s)
        } else {
            format!("Memory\n{}", self.mem)
        };
        let my_class = match self.mem.usage.u() {
            50.. => State::Good,
            25..=49 => State::Warn,
            _ => State::Critical,
        }
        .to_string();
        waybar_fmt(&text, &text, &details, &my_class, Some(self.mem.usage))
    }
}

/// Let me know if there are any better nerdfont icons for this
const MEMORY_ICON: Icon = '󰭰';

/// TODO: Add configuration for format string
#[derive(Debug, Clone, Copy)]
pub struct Memory {
    pub total: Size,
    pub free: Size,
    pub available: Size,
    pub used: Size,
    pub usage: Percent,
}
impl Memory {
    pub fn new(total: u64, free: u64, available: u64, used: u64) -> Option<Self> {
        Some(Self {
            total: Size::from_bytes(total),
            free: Size::from_bytes(free),
            available: Size::from_bytes(available),
            used: Size::from_bytes(used),
            usage: Percent::new(total, used)?,
        })
    }
    pub fn new_from_mem_sysinfo(info: &sysinfo::System) -> Option<Self> {
        Self::new(
            info.total_memory(),
            info.free_memory(),
            info.available_memory(),
            info.used_memory(),
        )
    }
    pub fn new_from_swap_sysinfo(info: &sysinfo::System) -> Option<Self> {
        let used_swap = info.used_swap();
        let total = info.total_swap();
        // if it doesn't exist or isn't used, why even bother
        if used_swap == 0 || total == 0 {
            None
        } else {
            Self::new(total, info.free_swap(), 0, used_swap)
        }
    }
}

impl std::fmt::Display for Memory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "Total: {}, Free: {}, Available: {}, Used: {}, Usage: {}",
            self.total, self.free, self.available, self.used, self.usage
        )
    }
}

/// Preferences for the memory module
#[derive(Debug, SmartDefault, Serialize, Deserialize)]
pub struct MemoryConfig {
    /// Enable the module
    #[default(AutoBool::default())]
    enable: AutoBool,
    /// Show swap
    #[default(AutoBool::default())]
    swap: AutoBool,
    /// Polling rate
    #[default = 5]
    poll_rate: usize,
    /// Format string
    #[default = "{icon} {usage}"]
    format: String,
}

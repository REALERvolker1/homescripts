use super::*;
use modules::*;
// use crate::*;

#[derive(Debug)]
pub struct MemoryModule {
    poll_rate: Duration,
    system: System,
}
impl Module for MemoryModule {
    type StartupData = SystemInfoConfig;
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        if data.show_memory {
            let mut me = Self {
                poll_rate: data.memory_poll_rate,
                system: System::new(),
            };
            let my_data = me.get_data();
            Ok((me, my_data.into()))
        } else {
            Err(ModError::ModuleSkip("Memory module not enabled. Skipping"))
        }
    }
    async fn run(&mut self, sender: ModuleSender) -> ModResult<()> {
        loop {
            let poll = join!(sleep!(self.poll_rate), sender.send(self.get_data().into()));
            poll.1?;
        }
    }
}
impl MemoryModule {
    pub fn get_data(&mut self) -> Memory {
        self.system.refresh_memory();
        Memory::from_sysinfo(&self.system)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Memory {
    pub total: u64,
    pub used: u64,
    pub percent: Percent,
    // pub free: u64,
    // pub available: u64,
    pub swap_total: u64,
    pub swap_used: u64,
    pub swap_percent: Option<Percent>,
    // pub swap_free: u64,
}
impl Memory {
    pub fn from_sysinfo(info: &sysinfo::System) -> Self {
        let total = info.total_memory();
        let used = info.used_memory();
        let percent = Percent::of_numbers(used, total);

        let swap_total = info.total_swap();
        let swap_used = info.used_swap();
        let swap_percent = if swap_used == 0 {
            None
        } else {
            Some(Percent::of_numbers(swap_used, swap_total))
        };

        Self {
            total,
            used,
            percent,
            swap_total,
            swap_used,
            swap_percent,
        }
    }
}
impl fmt::Display for Memory {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if let Some(s) = self.swap_percent {
            write!(f, "{} {}", self.percent, s)
        } else {
            write!(f, "{}", self.percent)
        }
    }
}

use super::*;
use sysinfo::System;

const DEFAULT_POLL_RATE: u64 = 5;

#[derive(Debug, Clone, Copy, Parser, SmartDefault, Deserialize, Serialize)]
pub struct CpuConfig {
    #[default(DEFAULT_POLL_RATE)]
    #[arg(long, default_value_t = DEFAULT_POLL_RATE, help = "The cpu poll rate, in seconds")]
    pub cpu_poll_rate: u64,
}

#[derive(Debug)]
pub struct CpuModule {
    poll_rate: Duration,
    system: System,
}
impl Module for CpuModule {
    type StartupData = CpuConfig;
    #[tracing::instrument(skip(data))]
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        let mut me = Self {
            poll_rate: Duration::from_secs(data.cpu_poll_rate),
            system: System::new(),
        };
        me.system.refresh_cpu();
        sleep!(sysinfo::MINIMUM_CPU_UPDATE_INTERVAL).await;
        let my_data = me.get_data();
        Ok((me, my_data.into()))
    }
    #[tracing::instrument(skip(self, sender))]
    async fn run(&mut self, sender: ModuleSender) -> ModResult<()> {
        loop {
            let res = join!(sleep!(self.poll_rate), sender.send(self.get_data().into()));
            res.1?;
        }
    }
}
impl CpuModule {
    pub fn get_data(&mut self) -> Cpu {
        self.system.refresh_cpu();
        Cpu::from_sysinfo(&self.system)
    }
}

#[derive(
    Debug,
    Clone,
    Copy,
    Default,
    strum_macros::Display,
    strum_macros::FromRepr,
    strum_macros::VariantArray,
    strum_macros::AsRefStr,
)]
#[repr(u64)]
pub enum FrequencyUnit {
    THz = 1_000_000_000_000,
    GHz = 1_000_000_000,
    MHz = 1_000_000,
    KHz = 1_000,
    #[default]
    Hz = 1,
}
impl FrequencyUnit {
    /// TODO: Find a better way to do this
    pub fn for_int(freq: u64) -> Self {
        if freq >= Self::THz as u64 {
            Self::THz
        } else if freq >= Self::GHz as u64 {
            Self::GHz
        } else if freq >= Self::MHz as u64 {
            Self::MHz
        } else if freq >= Self::KHz as u64 {
            Self::KHz
        } else {
            Self::Hz
        }
    }
    pub fn into_fucking_float(self, freq: u64) -> FuckingFloat {
        let divided_freq = freq as f64 / (self as u64 as f64);
        FuckingFloat::from(divided_freq)
    }
}

#[derive(Debug, Clone, Copy, Default, derive_more::Display)]
#[display(fmt = "{}% @ {}{}", usage, frequency, frequency_unit)]
pub struct Cpu {
    pub usage: FuckingFloat,
    /// The CPU frequency, rounded
    pub frequency: FuckingFloat,
    pub frequency_unit: FrequencyUnit,
}
impl Cpu {
    pub fn from_sysinfo(system: &sysinfo::System) -> Self {
        let cpu = system.global_cpu_info();
        let frequency = cpu.frequency();
        let frequency_unit = FrequencyUnit::for_int(frequency);
        Self {
            usage: cpu.cpu_usage().into(),
            frequency: frequency_unit.into_fucking_float(frequency),
            frequency_unit,
        }
    }
}

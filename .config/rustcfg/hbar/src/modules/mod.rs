pub mod battery;
pub mod cpu;
pub mod disks;
pub mod memory;
pub mod power_profiles_daemon;
pub mod supergfxd;
pub mod time;
pub mod weather;
pub mod workspaces;

use crate::*;
use std::sync::atomic::{AtomicBool, Ordering};

lazy_static! {
    pub static ref MODULES_INITIALIZED: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
}

/// All the modules
///
/// Some stuff has static lifetimes, I trust myself not to break it, because this is meant
/// to be a singleton.
#[derive(Debug)]
pub struct Modules {
    pub battery_sysfs: Option<battery::sysfs::SysFs>,
    pub battery_upower: Option<battery::upower::UPowerModule<'static>>,
    pub time: Option<time::Time>,
    pub weather: Option<weather::Weather>,
    pub power_profile: Option<power_profiles_daemon::PowerProfiles<'static>>,
    pub supergfxd: Option<supergfxd::GfxModule<'static>>,
    pub memory: Option<memory::MemoryModule>,
    pub cpu: Option<cpu::CpuModule>,
    pub disks: Option<disks::DiskModule>,
}
impl Modules {
    pub async fn new(sender: ModuleSender) -> ModResult<Self> {
        // there was already an instance of this. If there wasn't,
        // then we already swapped the value to true so it's safe
        if MODULES_INITIALIZED.swap(true, Ordering::SeqCst) {
            return Err(ModError::KnownError("modules already initialized"));
        }

        let cfg = config::Config::new().await?;

        // I'm pretty sure this will drop if it isn't required by anything.
        let system_connection = Arc::new(Connection::system().await?);

        // all the init values I want to send
        let mut inits = Vec::new();

        // helper macro. $var is the variable you want to set, $var1 is a random placeholder because the
        // rust people have been arguing about concat_ident! for over 9 fucking years, and $module is the module init function.
        macro_rules! init_var_v2 {
            ($($var:ident $var1:ident = $module:expr),+$(,)?) => {
                let ($($var1),+) = join!($($module),+);
                $(
                    let ($var, state) = unerr_tuple!($var1);
                    if let Some(s) = state {
                        inits.push(sender.send(s));
                    } else {
                        inits.push(sender.send(ModuleData::Uninitialized(stringify!($var))));
                    }
                )+
            };
        }

        init_var_v2!(
            battery b = battery::BatteryRunType::new(cfg.battery, Arc::clone(&system_connection)),
            power_profile p = power_profiles_daemon::PowerProfiles::new(Arc::clone(&system_connection)),
            supergfxd s = supergfxd::GfxModule::new(Arc::clone(&system_connection)),
            time t = time::Time::new(cfg.time),
            weather w = weather::Weather::new(cfg.weather),
            memory m = memory::MemoryModule::new(cfg.memory),
            cpu c = cpu::CpuModule::new(cfg.cpu),
            disks d = disks::DiskModule::new(cfg.disks)
        );

        let (battery_sysfs, battery_upower) = if let Some(bat) = battery {
            bat.unwrap_tuple()
        } else {
            (None, None)
        };

        // send all the data up the pipe
        futures_util::future::try_join_all(inits.into_iter()).await?;

        Ok(Self {
            battery_sysfs,
            battery_upower,
            time,
            weather,
            power_profile,
            supergfxd,
            memory,
            cpu,
            disks,
        })
    }
    /// Runs all the modules, consumes self.
    pub async fn run(self, sender: ModuleSender) -> ModResult<()> {
        let sender = Arc::clone(&sender);
        macro_rules! run {
            ($($module:tt),+$(,)?) => {
                $(
                    if let Some(mut m) = self.$module {
                        let my_sender = Arc::clone(&sender);
                        tokio::spawn(async move {
                            m.run(my_sender).await
                        });
                    }
                )+
            };
        }

        run!(
            battery_sysfs,
            battery_upower,
            time,
            weather,
            power_profile,
            supergfxd,
            memory,
            cpu,
            disks
        );
        Ok(())
    }
}

/// All the different types that can be received from a module
#[derive(
    Debug,
    derive_more::From,
    derive_more::Display,
    strum_macros::EnumDiscriminants,
    strum_macros::EnumTryAs,
    strum_macros::IntoStaticStr,
)]
#[strum_discriminants(derive(
    Serialize,
    Deserialize,
    strum_macros::Display,
    strum_macros::VariantArray,
    Hash
))]
#[strum_discriminants(serde(rename_all = "lowercase"))]
pub enum ModuleData {
    Workspaces(workspaces::WorkspaceData),
    Battery(battery::BatteryStatus),
    Time(time::DateTimeData),
    Weather(String),
    PowerProfile(power_profiles_daemon::PowerProfileState),
    Supergfxd(supergfxd::GfxState),
    Memory(memory::Memory),
    Cpu(cpu::Cpu),
    Disks(disks::DiskList),
    Uninitialized(&'static str),
}

/// The configuration for which modules you want to see where
///
/// TODO: Update default when more modules are added
#[derive(Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ModuleConfig {
    pub left: Vec<ModuleDataDiscriminants>,
    pub center: Vec<ModuleDataDiscriminants>,
    pub right: Vec<ModuleDataDiscriminants>,
}
impl Default for ModuleConfig {
    fn default() -> Self {
        Self {
            left: vec![ModuleDataDiscriminants::Workspaces],
            center: vec![ModuleDataDiscriminants::Time],
            right: vec![
                ModuleDataDiscriminants::Battery,
                ModuleDataDiscriminants::Memory,
                ModuleDataDiscriminants::Cpu,
                ModuleDataDiscriminants::Disks,
                ModuleDataDiscriminants::PowerProfile,
                ModuleDataDiscriminants::Supergfxd,
                ModuleDataDiscriminants::Weather,
                ModuleDataDiscriminants::Time,
            ],
        }
    }
}
pub type ModuleSender = Arc<Sender<ModuleData>>;
pub type SyncModuleSender = Arc<std::sync::mpsc::Sender<ModuleData>>;

/// The shared trait for all modules.
///
/// This program is designed to give as much control to modules as possible, but please keep
/// some best practices in mind:
/// - Do not put any heavy computation or much blocking logic in the `run` method.
/// - Design the `new` method to fail fast if it must.
///
/// The `new` method should be used to initialize the module. Immediately after running `new`,
/// the `initial_data` method is called and that result is taken as the module's startup data.
///
/// Basically you can construct modules however you want because my last design was very rigid and it took like 45 minutes to properly add a module.
#[allow(async_fn_in_trait)]
pub trait Module: Sized {
    /// The data that the module needs to start up
    type StartupData: Send + Sync;
    /// Run this module. It will asynchronously "block" indefinitely or until it errors,
    /// so it should ideally be run on a tokio task.
    async fn run(&mut self, sender: ModuleSender) -> ModResult<()>;
    /// Initialize this module, returning itself and the initial data that the bar needs to initialize the module on startup.
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)>;
}

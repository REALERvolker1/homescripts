pub mod battery;
pub mod power_profiles_daemon;
pub mod supergfxd;
pub mod system_info;
pub mod time;
pub mod weather;

use crate::*;

#[derive(Debug)]
pub struct Modules {
    pub battery_sysfs: Option<battery::sysfs::SysFs>,
    pub battery_upower: Option<battery::upower::UPowerModule<'static>>,
    pub time: Option<time::Time>,
    pub weather: Option<weather::Weather>,
    pub power_profile: Option<power_profiles_daemon::PowerProfiles<'static>>,
    pub supergfxd: Option<supergfxd::GfxModule<'static>>,
    pub memory: Option<system_info::memory::MemoryModule>,
    pub cpu: Option<system_info::cpu::CpuModule>,
    pub disks: Option<system_info::disks::DiskModule>,
}
impl Modules {
    pub async fn new(sender: ModuleSender) -> ModResult<Self> {
        let cfg = config::Config::new().await?;

        // TODO: Make this optional
        let system_connection = Arc::new(Connection::system().await?);

        // all the init values I want to send
        let mut inits = Vec::new();

        // helper macro. $var is the variable you want to set, $var1 is a random placeholder because the
        // rust people have been dawdling about concat_ident! for over 9 fucking years, and $module is the module init function.
        macro_rules! init_var_v2 {
            ($($var:ident $var1:ident = $module:expr),+$(,)?) => {
                let ($($var1),+) = join!($($module),+);
                $(
                    let ($var, state) = unerr_tuple!($var1);
                    if let Some(s) = state {
                        inits.push(s);
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
            memory m = system_info::memory::MemoryModule::new(cfg.sysinfo),
            cpu c = system_info::cpu::CpuModule::new(cfg.sysinfo),
            disks d = system_info::disks::DiskModule::new(cfg.sysinfo)
        );

        let (battery_sysfs, battery_upower) = if let Some(bat) = battery {
            bat.unwrap_tuple()
        } else {
            (None, None)
        };

        // send all the data up the pipe
        futures_util::future::try_join_all(inits.into_iter().map(|s| sender.send(s))).await?;

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
pub enum ModuleData {
    Battery(battery::BatteryStatus),
    Time(time::DateTimeData),
    Weather(String),
    PowerProfile(power_profiles_daemon::PowerProfileState),
    Supergfxd(supergfxd::GfxState),
    Memory(system_info::memory::Memory),
    Cpu(system_info::cpu::Cpu),
    Disks(system_info::disks::DiskList),
}

pub type ModuleSender = Arc<Sender<ModuleData>>;
pub type SyncModuleSender = Arc<std::sync::mpsc::Sender<ModuleData>>;

// /// A synchronous module. For more information, see [`Module`].
// pub trait SyncModule: Sized {
//     type StartupData: Send + Sync;
//     fn run(&mut self, sender: ModuleSender) -> ModResult<()>;
//     fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)>;
// }

/// The shared trait for all modules.
///
/// This program is designed to give as much control to modules as possible, but please keep
/// some best practices in mind:
/// - Do not put any heavy computation or much blocking logic in the `run` method.
/// - Design the `new` method to fail fast if it must.
///
/// The `new` method should be used to initialize the module. Immediately after running `new`,
/// the `initial_data` method is called and that result is taken as the module's startup data.
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

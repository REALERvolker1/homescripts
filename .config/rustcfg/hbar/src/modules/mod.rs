pub mod cpu;
pub mod disks;
pub mod memory;
pub mod power_profiles_daemon;
pub mod supergfxd;
pub mod time;
pub mod upower;
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
///
/// To add modules, add all their types into the required fields in this file,
/// then add the config to config.rs to receive configurations.
#[derive(Debug)]
pub struct Modules {
    pub battery: Option<upower::UPowerModule<'static>>,
    pub time: Option<time::TimeModule>,
    pub weather: Option<weather::WeatherModule>,
    pub power_profile: Option<power_profiles_daemon::PowerProfiles<'static>>,
    pub supergfxd: Option<supergfxd::GfxModule<'static>>,
    pub memory: Option<memory::MemoryModule>,
    pub cpu: Option<cpu::CpuModule>,
    pub disks: Option<disks::DiskModule>,
}
impl Modules {
    // #[tracing::instrument(skip_all, level = "debug")]
    #[tracing::instrument(skip_all, level = "debug")]
    pub async fn new(sender: ModuleSender) -> color_eyre::Result<Self> {
        // there was already an instance of this. If there wasn't,
        // then we already swapped the value to true so it's safe
        if MODULES_INITIALIZED.swap(true, Ordering::SeqCst) {
            return Err(ModError::KnownError("modules already initialized").into());
        }

        let client = Arc::new(
            reqwest::ClientBuilder::new()
                .timeout(Duration::from_secs(30))
                .connection_verbose(true)
                .build()?,
        );

        // I'm pretty sure this will drop if it isn't required by anything.
        let system_connection = Arc::new(Connection::system().await?);

        // all the init values I want to send
        let mut inits = Vec::new();

        /// helper macro. $var is the variable you want to set, $var1 is a random placeholder because the
        /// rust people have been arguing about concat_ident! for over 9 fucking years, and $module is the module init function.
        macro_rules! init_var_v2 {
            ($($var:ident $var1:ident = $module:expr),+$(,)?) => {
                let ($($var1),+) = join!($($module),+);
                $(
                    let ($var, state) = match $var1 {
                        Ok(unerrd) => (Some(unerrd.0), Some(unerrd.1)),
                        Err(e) => {
                            ::tracing::error!("{e}");
                            (None, None)
                        }
                    };
                    if let Some(s) = state {
                        inits.push(sender.send(s));
                    } else {
                        inits.push(sender.send(ModuleData::Uninitialized(stringify!($var))));
                    }
                )+
            };
        }

        init_var_v2!(
            battery b = upower::UPowerModule::new(Arc::clone(&system_connection)),
            power_profile p = power_profiles_daemon::PowerProfiles::new(Arc::clone(&system_connection)),
            supergfxd s = supergfxd::GfxModule::new(Arc::clone(&system_connection)),
            time t = time::TimeModule::new(()),
            weather w = weather::WeatherModule::new(Arc::clone(&client)),
            memory m = memory::MemoryModule::new(()),
            cpu c = cpu::CpuModule::new(()),
            disks d = disks::DiskModule::new(())
        );

        // send all the data up the pipe
        futures_util::future::try_join_all(inits.into_iter()).await?;

        Ok(Self {
            battery,
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
    #[tracing::instrument(skip_all, level = "debug")]
    pub async fn run(self, sender: ModuleSender) -> color_eyre::Result<()> {
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
            battery,
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
    ValueEnum,
    strum_macros::Display,
    strum_macros::VariantArray,
    Hash
))]
#[strum_discriminants(serde(rename_all = "lowercase"))]
#[strum_discriminants(strum(serialize_all = "lowercase"))]
#[strum_discriminants(clap(rename_all = "lowercase"))]
pub enum ModuleData {
    Workspaces(workspaces::WorkspaceData),
    Battery(upower::BatteryStatus),
    Time(time::DateTimeData),
    Weather(String),
    PowerProfile(power_profiles_daemon::PowerProfileState),
    Supergfxd(supergfxd::GfxState),
    Memory(memory::Memory),
    Cpu(cpu::Cpu),
    Disks(disks::DiskList),
    Uninitialized(&'static str),
}
config_struct! {
    ModuleConfig, ModuleConfigOptions,

    default: vec![ModuleDataDiscriminants::Workspaces],
    help: "Modules to show in the left side of the bar",
    long_help: "Modules to show in the left side of the bar",
    left_modules: Vec<ModuleDataDiscriminants>,

    default: vec![ModuleDataDiscriminants::Time],
    help: "Modules to show in the center of the bar",
    long_help: "Modules to show in the center of the bar",
    center_modules: Vec<ModuleDataDiscriminants>,

    default: vec![
        ModuleDataDiscriminants::Battery,
        ModuleDataDiscriminants::Memory,
        ModuleDataDiscriminants::Cpu,
        ModuleDataDiscriminants::Disks,
        ModuleDataDiscriminants::PowerProfile,
        ModuleDataDiscriminants::Supergfxd,
        ModuleDataDiscriminants::Weather,
    ],
    help: "Modules to show in the right side of the bar",
    long_help: "Modules to show in the right side of the bar",
    right_modules: Vec<ModuleDataDiscriminants>,
}

pub type ModuleSender = Arc<Sender<ModuleData>>;

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

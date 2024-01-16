use crate::types::*;
use serde::{Deserialize, Serialize};
use smart_default::SmartDefault;
pub mod memory;
pub mod mpris;
pub mod power_profiles;
pub mod supergfxd;
pub mod upower;

/// run a bunch of modules with this.
///
/// It takes a mutable array of tasks, an IPC connection, and a list of module results.
macro_rules! run_module {
    ($modarr:expr, $srv: expr, $($mod:expr),*) => {
        $(if let Ok(mut m) = $mod.await {
            if m.should_run() {
                let arc = std::sync::Arc::clone($srv);
                $modarr.push(tokio::spawn(async move {
                    if let Err(e) = m.run(arc).await {
                        tracing::error!("Error in module: {}", e);

                        #[cfg(not(debug_assertions))]
                        eprintln!("Error in module: {}", e);
                    }
                }))
            }
        })*
    };
}

/// Load all the modules -- for use at like runtime or something
#[tracing::instrument(skip(connection))]
pub async fn load_modules(
    connection: &zbus::Connection,
    ipc: &IpcCh,
) -> ModResult<Vec<tokio::task::JoinHandle<()>>> {
    let mut modules = Vec::new();

    // let (sgf, ppd, upw, mem) = tokio::join!(
    //     supergfxd::SuperGfxModule::new(connection),
    //     power_profiles::PowerProfilesModule::new(connection),
    //     upower::UpowerModule::new(connection),
    //     memory::MemoryModule::new(memory::MEM_POLL_RATE),
    // );

    // run_module!(modules, ipc, sgf, ppd, upw, mem);
    run_module!(
        modules,
        ipc,
        supergfxd::SuperGfxModule::new(connection),
        power_profiles::PowerProfilesModule::new(connection),
        upower::UpowerModule::new(connection),
        memory::MemoryModule::new(memory::MEM_POLL_RATE)
    );

    Ok(modules)
}

/// All the types of modules
#[derive(Debug, Default, Clone, Copy, Serialize, Deserialize)]
pub enum ModuleType {
    Dbus,
    DbusGetter,
    Command,
    Poll,
    #[default]
    Static,
}

/// The base trait for all modules that are dynamic and updating
pub trait Module: Sized + StaticModule {
    async fn update(&mut self, payload: RecvType) -> ModResult<()>;
    /// The runtime function. this should update the IPC state instantly on load,
    /// then wait for new status updates, sending them to the channel.
    async fn run(&mut self, ipc: IpcCh) -> ModResult<()>;
    /// Call this to determine if the module should be updated
    fn should_run(&self) -> bool;
}

/// A module that doesn't have to be updated ever
pub trait StaticModule: Sized {
    /// The name of the module
    fn name(&self) -> &str;
    /// The type of the module
    fn mod_type(&self) -> ModuleType;
    /// The current status of the module.
    /// Should not have anything computationally intensive in it, that's for the update or init function
    async fn update_server(&self, ipc: &IpcCh) -> ModResult<()>;
}

/// The trait for modules that connect to dbus
pub trait DbusModule<'a>: Module {
    /// Create a new instance of the dbus module
    async fn new(connection: &zbus::Connection) -> ModResult<Self>;
}

/// The trait for a module that polls its status
pub trait PollModule: Module {
    /// Create a new instance of the polling module
    async fn new(poll_rate: std::time::Duration) -> ModResult<Self>;
}

/// This is the trait for module return values that can output their data
pub trait FmtModule: Sized {
    fn stdout(&self) -> String;
    fn waybar(&self) -> String;
    fn with_output_type(&self, output_type: OutputType) -> String {
        match output_type {
            OutputType::Waybar => self.waybar(),
            OutputType::Stdout => self.stdout(),
        }
    }
}

/// The main configuration for modules
#[derive(Debug, Default, Serialize, Deserialize)]
pub struct ModuleConfig {
    pub upower: upower::UPowerConfig,
    pub power_profiles: power_profiles::PowerProfilesConfig,
    pub supergfxd: supergfxd::SuperGfxConfig,
    pub memory: memory::MemoryConfig,
}

// #[derive(Debug, Clone, strum_macros::EnumIs, strum_macros::Display, Serialize, Deserialize)]
// pub enum ModuleName {
//     Upower,
//     PowerProfiles,
//     SuperGfxd,
// }

/// The types of data that can be sent to IPC handlers by modules
#[derive(
    Debug, Clone, strum_macros::EnumDiscriminants, strum_macros::Display, Serialize, Deserialize,
)]
pub enum StateType {
    UPower(upower::UPowerStatus),
    PowerProfiles(power_profiles::PowerProfileState),
    SuperGfxd(supergfxd::GfxState),
    Memory(String),
    Anonymous(String),
}

// pub type Ipc = std::sync::Arc<parking_lot::Mutex<IpcChannel>>;
pub type IpcCh = std::sync::Arc<tokio::sync::mpsc::Sender<StateType>>;

/// The types of data that can be sent and received by modules
///
/// Each type must be serializable and deserializable, and it must be able to be cast `Into<RecvType>`
#[derive(Debug, Default, Clone, strum_macros::EnumIs, Serialize, Deserialize)]
pub enum RecvType {
    String(String),
    Percent(Percent),
    Float(f64),
    Multi(Vec<RecvType>),
    /// Custom type for the Power Profiles Daemon module
    PowerProfile(power_profiles::PowerProfileState),
    /// Custom type for the upower module
    BatteryState(upower::BatteryState),
    /// These NotifyStatus types are returned from modules that don't support
    /// property stream watchers, and is used to prompt the module to manually request a refresh.
    NotifyStatus,
    #[default]
    Null,
}

pub fn waybar_fmt(
    text: &str,
    alt_text: &str,
    tooltip: &str,
    class: &str,
    percentage: Option<Percent>,
) -> String {
    format!(
        r#"{{"text": "{}", "alt": "{}", "tooltip": "{}", "class": "{}", "percentage": {}}}"#,
        text,
        alt_text,
        tooltip,
        class,
        percentage.unwrap_or_default().u()
    )
}

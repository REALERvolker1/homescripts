use crate::types::*;
use serde::{Deserialize, Serialize};
use smart_default::SmartDefault;
pub mod mpris;
pub mod power_profiles;
// pub mod server;
pub mod supergfxd;
pub mod upower;

macro_rules! run_module {
    ($modarr:expr, $srv: expr, $($mod:expr),*) => {
        $(if let Ok(mut m) = $mod {
            if m.should_run() {
                let arc = std::sync::Arc::clone($srv);
                $modarr.push(tokio::spawn(async move {
                    m.run(arc).await
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
) -> Result<Vec<tokio::task::JoinHandle<()>>, ModError> {
    let mut modules = Vec::new();

    let (sgf, ppd, upw) = tokio::join!(
        supergfxd::SuperGfxModule::new(connection),
        power_profiles::PowerProfilesModule::new(connection),
        upower::UpowerModule::new(connection)
    );

    run_module!(modules, ipc, sgf, ppd, upw);
    // run_module!(modules, server, ppd);
    // run_module!(modules, server, upw);

    Ok(modules)
}

/// All the types of modules
#[derive(Debug, Default, Clone, Copy, Serialize, Deserialize)]
pub enum ModuleType {
    Dbus,
    DbusGetter,
    Command,
    #[default]
    Static,
}

/// The base trait for all modules that are dynamic and updating
pub trait Module: Sized + StaticModule {
    async fn update(&mut self, payload: RecvType) -> Result<(), ModError>;
    /// Create a new instance of the module
    async fn new(connection: &zbus::Connection) -> Result<Self, ModError>;
    /// The runtime function, This is run in a background task.
    async fn run(&mut self, ipc: IpcCh);
    /// Call this to determine if the module should be run
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
    async fn update_server(&self, ipc: &IpcCh);
}

/// This is the trait for modules that can output their data
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

#[derive(Debug, SmartDefault, Serialize, Deserialize)]
pub struct ModuleConfig {
    pub upower: upower::UPowerConfig,
    pub power_profiles: power_profiles::PowerProfilesConfig,
    pub supergfxd: supergfxd::SuperGfxConfig,
}

#[derive(Debug, Clone, strum_macros::EnumIs, strum_macros::Display, Serialize, Deserialize)]
pub enum ModuleName {
    Upower,
    PowerProfiles,
    SuperGfxd,
}

/// The types of data that can be sent to IPC handlers by modules
#[derive(Debug, Clone, strum_macros::EnumIs, strum_macros::Display, Serialize, Deserialize)]
pub enum StateType {
    UPower(upower::UPowerStatus),
    PowerProfiles(power_profiles::PowerProfileState),
    SuperGfxd(supergfxd::GfxState),
}
impl FmtModule for StateType {
    fn stdout(&self) -> String {
        match self {
            Self::UPower(s) => s.stdout(),
            Self::PowerProfiles(s) => s.stdout(),
            Self::SuperGfxd(s) => s.stdout(),
        }
    }
    fn waybar(&self) -> String {
        match self {
            Self::UPower(s) => s.waybar(),
            Self::PowerProfiles(s) => s.waybar(),
            Self::SuperGfxd(s) => s.waybar(),
        }
    }
    fn with_output_type(&self, output_type: OutputType) -> String {
        match output_type {
            OutputType::Waybar => self.waybar(),
            OutputType::Stdout => self.stdout(),
        }
    }
}

// pub type Ipc = std::sync::Arc<parking_lot::Mutex<IpcChannel>>;
pub type IpcCh = std::sync::Arc<tokio::sync::mpsc::Sender<StateType>>;

// #[derive(Debug)]
// pub struct IpcChannel {
//     send: tokio::sync::mpsc::Sender<StateType>,
//     recv: tokio::sync::mpsc::Receiver<StateType>,
// }
// impl Default for IpcChannel {
//     #[tracing::instrument]
//     fn default() -> Self {
//         let (send, recv) = tokio::sync::mpsc::channel(1);
//         Self { send, recv }
//     }
// }
// impl IpcChannel {
//     pub fn new() -> Ipc {
//         std::sync::Arc::new(parking_lot::Mutex::new(Self::default()))
//     }
//     pub async fn send(&mut self, payload: StateType) -> Result<(), ModError> {
//         self.send.send(payload).await?;
//         Ok(())
//     }
//     pub async fn recv(&mut self) -> Option<StateType> {
//         self.recv.recv().await
//     }
// }

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

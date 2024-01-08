//! The properties of a block
use async_trait::async_trait;
use futures::StreamExt;

pub mod power_profiles;
pub mod supergfxd;
pub mod upower;

/// The type for an icon
pub type Icon = &'static str;

/// What kind of output is requested
#[derive(Debug, Clone, Copy)]
pub enum OutputType {
    Stdout,
    Waybar,
    // TODO: Add more output types
}

/// All the types of module, because async traits can't be `Box`ed
pub enum Property<'a> {
    Battery(Option<upower::Battery<'a>>),
    PowerProfile(Option<power_profiles::PowerProfile<'a>>),
    SuperGFX,
    None,
}
impl<'a> Property<'a> {
    pub fn to_string(&self) -> String {
        match self {
            Self::Battery(battery) => "battery",
            Self::PowerProfile(profile) => "power_profile",
            _ => "",
        }
        .to_owned()
    }
    /// Get the (nulled) proptype of Self
    pub fn proptype(&self) -> Self {
        match self {
            Self::Battery(_) => Self::Battery(None),
            Self::PowerProfile(_) => Self::PowerProfile(None),
            _ => Self::None,
        }
    }
}
impl<'a> futures::Stream for Property<'a> {
    type Item = PropertyListener<'a>;
    fn poll_next(
        self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        match self.get_mut() {
            Property::Battery(Some(battery)) => battery.poll_next_unpin(cx),
            Property::PowerProfile(Some(profile)) => profile.poll_next_unpin(cx),
            _ => futures::task::Poll::Pending,
        }
    }
}

/// A catch-all enum for all the possible Property listener types.
///
/// This is used for finding the struct to update
#[derive(Default)]
pub enum PropertyListener<'a> {
    BatteryState(zbus::PropertyChanged<'a, u32>),
    BatteryPercentage(zbus::PropertyChanged<'a, f64>),
    BatteryRate(zbus::PropertyChanged<'a, f64>),
    PowerProfile(zbus::PropertyChanged<'a, String>),
    SuperGFX,
    #[default]
    None,
}
impl PropertyListener<'_> {
    pub fn to_proptype(&self) -> Property {
        match self {
            Self::BatteryState(_) => Property::Battery(None),
            Self::BatteryPercentage(_) => Property::Battery(None),
            Self::BatteryRate(_) => Property::Battery(None),
            Self::PowerProfile(_) => Property::PowerProfile(None),
            Self::SuperGFX => Property::SuperGFX,
            Self::None => Property::None,
        }
    }
}
impl std::fmt::Display for PropertyListener<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::BatteryState(_) => write!(f, "BatteryState"),
            Self::BatteryPercentage(_) => write!(f, "BatteryPercentage"),
            Self::BatteryRate(_) => write!(f, "BatteryRate"),
            Self::PowerProfile(_) => write!(f, "PowerProfile"),
            Self::SuperGFX => write!(f, "SuperGFX"),
            Self::None => write!(f, "None"),
        }
    }
}

/// The trait defining a module, not to be used without `Module`
pub trait ModuleExt<'a> {
    // TODO: Separate get_state and print
    /// Get the module's inner state
    fn get_state_string(&self, output_type: OutputType) -> String;
    /// Immediately require a full state update
    async fn refresh_state(&mut self) -> zbus::Result<()>;
    /// Create a new instance of the module, returning a Property supported by the event listener
    async fn new(connection: &zbus::Connection) -> zbus::Result<Property<'a>>;
    /// Get the Property type that corresponds to this module
    fn proptype(&self) -> Property<'a>;
}

/// The trait for a module.
/// ```
/// impl<'a> modules::Module for Battery<'a>
/// impl<'a> futures::Stream for Battery<'a>
/// impl<'a> modules::ModuleExt for Battery<'a>
/// ```
pub trait Module<'a>: ModuleExt<'a> + futures::Stream {
    /// The function to call on a property change event
    async fn handle_event(&mut self, listener_type: PropertyListener) -> zbus::Result<Option<()>>;
    /// shitty workaround for tokio::task::JoinSet to work. Use this instead of `handle_event`.
    async fn handle_next(&mut self) -> zbus::Result<()>;
    // /// Get the module's listeners
    // fn get_listeners<T>(&self) -> Vec<&mut zbus::PropertyStream<'_, T>>;
}

/*
#[dynamic]
/// The global mutable state of this project
pub static mut STATE: Arc<Mutex<StateMux>> = Arc::new(Mutex::new(StateMux::new()));

/// The prototype for global mutable state of this project
#[derive(Debug, Default)]
pub struct StateMux {
    pub battery_state: upower::BatteryState,
    pub battery_rate: f64,
    pub battery_percentage: u8,
}
impl StateMux {
    pub fn new() -> StateMux {
        // let state_hash = PropertyListener::iter()
        //     .map(|x| (x.to_string(), x))
        //     .collect::<AHashMap<_, _>>();
        StateMux::default()
    }
}

*/

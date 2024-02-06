pub mod sysfs;
pub mod upower;
mod xmlgen;

use crate::*;

use super::ModuleData;

/// Configuration for the battery module
#[derive(Debug, Clone, Serialize, Deserialize, SmartDefault)]
pub struct BatteryConfig {
    /// Your chosen backend
    #[default(BatteryRunTypeDiscriminants::Auto)]
    pub backend: BatteryRunTypeDiscriminants,
    /// The rate at which to poll the battery when using the naive sysfs backend.
    #[default(FIVE_SECONDS)]
    pub sysfs_poll_rate: Duration,
    /// The battery number to use. For example, if you have two batteries, `BAT1` and `BAT2`, you
    /// can specify which one you choose to poll by setting this to `2`, for example to poll `BAT2`.
    pub sysfs_battery_number: Option<usize>,
}

#[derive(derive_more::From, Default, strum_macros::EnumDiscriminants)]
#[strum_discriminants(derive(Deserialize, Serialize))]
pub enum BatteryRunType<'a> {
    Sysfs(sysfs::SysFs),
    Upower(upower::UPowerModule<'a>),
    #[default]
    Auto,
}
impl<'a> BatteryRunType<'a> {
    pub fn unwrap_tuple(self) -> (Option<sysfs::SysFs>, Option<upower::UPowerModule<'a>>) {
        match self {
            Self::Sysfs(s) => (Some(s), None),
            Self::Upower(s) => (None, Some(s)),
            _ => (None, None),
        }
    }
    pub fn unwrap_sysfs(self) -> Option<sysfs::SysFs> {
        match self {
            BatteryRunType::Sysfs(s) => Some(s),
            _ => None,
        }
    }
    pub fn unwrap_upower(self) -> Option<upower::UPowerModule<'a>> {
        match self {
            BatteryRunType::Upower(s) => Some(s),
            _ => None,
        }
    }
    pub async fn new(
        config: BatteryConfig,
        dbus_connection: Arc<Connection>,
    ) -> ModResult<(Self, ModuleData)> {
        macro_rules! s {
            () => {
                sysfs::SysFs::new(config).await
            };
            (return $s:expr) => {
                (Self::Sysfs($s.0), $s.1.into())
            };
        }
        macro_rules! u {
            () => {
                upower::UPowerModule::new(dbus_connection).await
            };
            (return $s:expr) => {
                (Self::Upower($s.0), $s.1.into())
            };
        }
        match config.backend {
            BatteryRunTypeDiscriminants::Sysfs => {
                let sysfs = s!()?;
                Ok(s!(return sysfs))
            }
            BatteryRunTypeDiscriminants::Upower => {
                let upower = u!()?;
                Ok(u!(return upower))
            }
            _ => {
                if let Some(s) = unerr!(u!()) {
                    Ok(u!(return s))
                } else {
                    let sysfs = s!()?;
                    Ok(s!(return sysfs))
                }
            }
        }
    }
}
// impl Module for BatteryRunType<'_> {
//     type StartupData = BatteryConfig;
//     async fn new(data: Self::StartupData) -> ModResult<Self> {
//         match data.backend {
//             BatteryRunTypeDiscriminants::Sysfs => Ok(sysfs::SysFs::new(data).await?.into()),
//             BatteryRunTypeDiscriminants::Upower => Ok(upower::UPowerModule::new(data).await?.into()),
//         }
//     }
// }

/// The current status of the battery, mainly used for display formatting and saving state.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Deserialize, Serialize)]
pub struct BatteryStatus {
    pub status_icon: Icon,
    pub percentage: Percent,
    pub state: BatteryState,
    pub rate: FuckingFloat,
    show_rate: bool,
}
impl BatteryStatus {
    /// Basically just [`BatteryStatus::new`] but using current values
    pub fn set_rate(mut self, rate: FuckingFloat) {
        self = Self::new(self.state, self.percentage, rate);
    }

    /// Basically just [`BatteryStatus::new`] but using current values
    pub fn set_percentage(mut self, percentage: Percent) {
        self = Self::new(self.state, percentage, self.rate);
    }

    /// Basically just [`BatteryStatus::new`] but using current values
    pub fn set_state(mut self, state: BatteryState) {
        self = Self::new(state, self.percentage, self.rate);
    }

    #[inline]
    fn init_show_rate(rate: FuckingFloat, do_rate: bool) -> bool {
        do_rate && rate != FuckingFloat::MIN
    }
    fn init_icon_do_rate(state: BatteryState, percentage: Percent) -> (Icon, bool) {
        match state {
            BatteryState::Charging => (
                match percentage.into() {
                    95.. => '󰂅',
                    91.. => '󰂋',
                    81.. => '󰂊',
                    71.. => '󰢞',
                    61.. => '󰂉',
                    51.. => '󰢝',
                    41.. => '󰂈',
                    31.. => '󰂇',
                    21.. => '󰂆',
                    11.. => '󰢜',
                    0.. => '󰢟',
                },
                true,
            ),
            BatteryState::Discharging => (
                match percentage.into() {
                    95.. => '󰁹',
                    91.. => '󰂂',
                    81.. => '󰂁',
                    71.. => '󰂀',
                    61.. => '󰁿',
                    51.. => '󰁾',
                    41.. => '󰁽',
                    31.. => '󰁼',
                    21.. => '󰁻',
                    11.. => '󰁺',
                    00.. => '󰂎',
                },
                true,
            ),
            BatteryState::Empty => ('󱟩', true),
            BatteryState::FullyCharged => ('󰂄', false),
            BatteryState::PendingCharge => ('󰂏', true),
            BatteryState::PendingDischarge => ('󰂌', true),
            BatteryState::Unknown => ('󰂑', true),
        }
    }

    /// Create a new [`BatteryStatus`]
    pub fn new(state: BatteryState, percentage: Percent, rate: FuckingFloat) -> Self {
        let (status_icon, do_rate) = Self::init_icon_do_rate(state, percentage);
        Self {
            status_icon,
            percentage,
            state,
            rate,
            show_rate: Self::init_show_rate(rate, do_rate),
        }
    }
}
impl fmt::Display for BatteryStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.show_rate {
            // {:.1}
            write!(f, "{} {} {}W", self.status_icon, self.percentage, self.rate)
        } else {
            write!(f, "{} {}", self.status_icon, self.percentage)
        }
    }
}

/// The current state of the battery, an enum based on its representation in upower
///
/// For upower, this is well-defined. For sysfs, check out `/usr/lib/modules/<kernel>/build/include/linux/power_supply.h`
#[derive(
    Debug,
    Copy,
    Clone,
    PartialEq,
    Eq,
    Default,
    strum_macros::Display,
    strum_macros::FromRepr,
    strum_macros::AsRefStr,
    strum_macros::EnumString,
    zvariant::Type,
    Deserialize,
    Serialize,
)]
#[strum(ascii_case_insensitive, serialize_all = "kebab-case")]
pub enum BatteryState {
    Charging = 1,
    Discharging = 2,
    Empty = 3,
    #[strum(
        serialize = "fully-charged",
        serialize = "Fully Charged",
        serialize = "Full"
    )]
    FullyCharged = 4,
    #[strum(serialize = "pending-charge", serialize = "Not Charging")]
    PendingCharge = 5,
    PendingDischarge = 6,
    #[default]
    Unknown = 0,
}
impl From<zvariant::OwnedValue> for BatteryState {
    fn from(value: zvariant::OwnedValue) -> Self {
        if let Some(v) = value.downcast_ref::<u32>() {
            Self::from_repr(*v as usize).unwrap_or_default()
        } else {
            Self::default()
        }
    }
}

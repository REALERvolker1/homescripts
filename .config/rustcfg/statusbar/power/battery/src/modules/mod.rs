use futures::StreamExt;

pub mod asusd;
pub mod power_profiles;
pub mod supergfxd;
pub mod upower;

/// All the types of Proxy, because async traits can't be `Box`ed
#[derive(strum_macros::EnumDiscriminants, strum_macros::Display)]
pub enum PropertyProxy<'a> {
    Battery(upower::BatteryProxy<'a>),
    PowerProfile(power_profiles::PowerProfileProxy<'a>),
    /// Asus is not a module, it just determines the waybar class
    Asus(asusd::AsusdProxy<'a>),
    SuperGFX,
}

impl<'a> futures::Stream for PropertyProxy<'a> {
    type Item = WeakStateType<'a>;
    fn poll_next(
        self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        match self.get_mut() {
            PropertyProxy::Battery(s) => {
                if let std::task::Poll::Ready(Some(v)) = s.poll_next_unpin(cx) {
                    return std::task::Poll::Ready(Some(v));
                }
            }
            PropertyProxy::PowerProfile(s) => {
                if let std::task::Poll::Ready(Some(v)) = s.poll_next_unpin(cx) {
                    return std::task::Poll::Ready(Some(v));
                }
            }
            _ => {}
        }
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
}
/// Connects to dbus, registers listeners, and gets the current state, all in one swell foop. May or may not exist.
pub trait Proxy<'a>: Sized + futures::Stream {
    async fn new(
        connection: &'a zbus::Connection,
    ) -> Option<(crate::modules::PropertyProxy, crate::modules::Property)>;
    fn name() -> String;
}

/// The type for an icon
pub type Icon = &'static str;

/// The global state
#[derive(Debug, Default)]
pub struct PropertyStore {
    pub config: crate::config::Config,
    pub battery: Option<upower::BatteryStatus>,
    pub charge_control_end: upower::Percent,
    /// Just here to cache the string value
    battery_status_string: String,
    pub class: Class,
    pub power_profile: Option<power_profiles::PowerProfileState>,
    pub supergfxd: Option<()>,
}
impl PropertyStore {
    #[inline]
    pub fn new() -> Self {
        Self::default()
    }
    pub fn print(&self) {
        println!(
            "{} {}",
            if let Some(b) = self.power_profile {
                b.icon()
            } else {
                ""
            },
            &self.battery_status_string,
        );
    }
    #[inline]
    fn update_battery_status(&mut self) -> Option<()> {
        self.battery_status_string = self.battery?.status_string();
        Some(())
    }
    /// Update the global state
    pub fn update(&mut self, data: StateType) -> Option<bool> {
        // There is a bug where you can't update attributes of a struct, make sure it's all direct
        let retval = match data {
            StateType::BatteryState(_)
            | StateType::BatteryPercentage(_)
            | StateType::BatteryRate(_) => {
                if let Some(mut bat) = self.battery {
                    bat.update_state(data);
                    self.update_battery_status()?;
                    Some(true)
                } else {
                    Some(false)
                }
            }
            StateType::PowerProfile(s) => {
                self.power_profile = Some(s);
                Some(true)
            }
            StateType::SuperGFX(s) => {
                self.supergfxd = Some(s);
                Some(true)
            }
            StateType::ChargeControl(s) => {
                self.charge_control_end = s;
                Some(true)
            }
            _ => Some(false),
        };

        self.update_class()?;
        retval
    }
    pub fn insert_property(&mut self, property: Property) -> &Self {
        match property {
            Property::Battery(s) => self.battery = Some(s),
            Property::PowerProfile(s) => self.power_profile = Some(s),
            Property::SuperGFX => self.supergfxd = Some(()),
            _ => {}
        }
        self
    }
    pub fn update_class(&mut self) -> Option<()> {
        let is_charging = self.battery?.state == upower::BatteryState::Charging;
        let is_above_threshold = self.battery?.percent > self.charge_control_end;
        let is_low_power = self.battery?.percent <= self.config.low_power;

        self.class = if is_charging {
            if is_above_threshold {
                Class::ChargingAboveThreshold
            } else if is_low_power {
                Class::ChargingLowPower
            } else if self.battery?.rate > self.config.ac_high_draw_threshold {
                Class::ChargingHighDraw
            } else {
                Class::Charging
            }
        } else {
            if is_above_threshold {
                Class::DischargingAboveThreshold
            } else if is_low_power {
                Class::DischargingLowPower
            } else if self.battery?.rate > self.config.ac_high_draw_threshold {
                Class::DischargingHighDraw
            } else {
                Class::Discharging
            }
        };

        Some(())
    }
}

/// The class of the waybar module(s)
#[derive(Debug, Copy, Clone, PartialEq, Eq, Default, strum_macros::Display)]
pub enum Class {
    Charging,
    Discharging,
    ChargingHighDraw,
    DischargingHighDraw,
    ChargingLowPower,
    DischargingLowPower,
    ChargingAboveThreshold,
    DischargingAboveThreshold,
    /// Everything is okay
    #[default]
    None,
}

#[derive(strum_macros::EnumDiscriminants, strum_macros::EnumIs, Default)]
pub enum Property {
    Battery(upower::BatteryStatus),
    PowerProfile(power_profiles::PowerProfileState),
    SuperGFX,
    #[default]
    None,
}

/// The weak owned state type, used to return from a module's futures::Stream
#[derive(Default, strum_macros::EnumDiscriminants, strum_macros::EnumIs)]
pub enum WeakStateType<'a> {
    BatteryState(zbus::PropertyChanged<'a, u32>),
    BatteryPercentage(zbus::PropertyChanged<'a, f64>),
    BatteryRate(zbus::PropertyChanged<'a, f64>),
    ChargeControl(zbus::PropertyChanged<'a, u8>),
    PowerProfile(zbus::PropertyChanged<'a, String>),
    SuperGFX(zbus::PropertyChanged<'a, ()>),
    #[default]
    None,
}

/// The strong owned state type, used to update the global state
#[derive(
    Debug, Default, Clone, PartialEq, strum_macros::EnumDiscriminants, strum_macros::EnumIs,
)]
pub enum StateType {
    BatteryState(upower::BatteryState),
    BatteryPercentage(upower::Percent),
    BatteryRate(f64),
    ChargeControl(upower::Percent),
    PowerProfile(power_profiles::PowerProfileState),
    SuperGFX(()),
    #[default]
    None,
}
impl StateType {
    pub async fn from_weak(weak_state: WeakStateType<'_>) -> zbus::Result<Self> {
        Ok(match weak_state {
            WeakStateType::BatteryState(s) => {
                if let Some(s) = upower::BatteryState::from_u32(s.get().await?) {
                    Self::BatteryState(s)
                } else {
                    Self::None
                }
            }
            WeakStateType::BatteryPercentage(s) => {
                Self::BatteryPercentage(s.get().await? as upower::Percent)
            }
            WeakStateType::BatteryRate(s) => Self::BatteryRate(s.get().await?),
            WeakStateType::ChargeControl(s) => Self::ChargeControl(s.get().await?),
            WeakStateType::PowerProfile(s) => Self::PowerProfile(
                power_profiles::PowerProfileState::from_string(s.get().await?),
            ),
            _ => Self::default(),
        })
    }
}

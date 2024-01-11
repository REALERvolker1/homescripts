//! To add properties to listen to, edit this file! Also check out store.rs
use crate::types::ModError;
use futures::{Stream, StreamExt};
use std::task::Poll;

pub mod asusd;
pub mod power_profiles;
pub mod store;
pub mod supergfxd;
pub mod upower;

/// The weak owned state type, used to return from a module's futures::Stream
#[derive(Default, strum_macros::EnumDiscriminants)]
pub enum WeakStateType<'a> {
    BatteryState(zbus::PropertyChanged<'a, upower::BatteryState>),
    BatteryPercentage(zbus::PropertyChanged<'a, upower::Percent>),
    BatteryRate(zbus::PropertyChanged<'a, f64>),
    ChargeControl(zbus::PropertyChanged<'a, upower::Percent>),
    PowerProfile(zbus::PropertyChanged<'a, power_profiles::PowerProfileState>),
    /// supergfxpower is void here because it does everything differently
    SuperGFXPower,
    #[default]
    None,
}

/// The strong owned state type, used to update the global state
#[derive(
    Debug,
    Default,
    Clone,
    strum_macros::EnumDiscriminants,
    strum_macros::EnumIs,
    strum_macros::Display,
)]
pub enum StateType {
    BatteryState(upower::BatteryState),
    BatteryPercentage(upower::Percent),
    BatteryRate(f64),
    ChargeControl(upower::Percent),
    PowerProfile(power_profiles::PowerProfileState),
    SuperGFXPower,
    #[default]
    None,
}
impl StateType {
    pub async fn from_weak(weak_state: WeakStateType<'_>) -> zbus::Result<Self> {
        let state = match weak_state {
            WeakStateType::BatteryState(s) => Self::BatteryState(s.get().await?),
            WeakStateType::BatteryPercentage(s) => Self::BatteryPercentage(s.get().await?),
            WeakStateType::BatteryRate(s) => Self::BatteryRate(s.get().await?),
            WeakStateType::ChargeControl(s) => Self::ChargeControl(s.get().await?),
            WeakStateType::PowerProfile(s) => Self::PowerProfile(s.get().await?),
            WeakStateType::SuperGFXPower => Self::SuperGFXPower,
            _ => Self::default(),
        };
        Ok(state)
    }
}

#[derive(strum_macros::EnumDiscriminants, strum_macros::EnumIs)]
pub enum ListenerType<'a> {
    BatteryState(zbus::PropertyStream<'a, upower::BatteryState>),
    BatteryPercentage(zbus::PropertyStream<'a, upower::Percent>),
    BatteryRate(zbus::PropertyStream<'a, f64>),
    ChargeControl(zbus::PropertyStream<'a, upower::Percent>),
    PowerProfile(zbus::PropertyStream<'a, power_profiles::PowerProfileState>),
    SuperGFXPower(supergfxd::SuperGfxPowerStream<'a>),
}
impl<'a> Stream for ListenerType<'a> {
    type Item = WeakStateType<'a>;
    fn poll_next(
        self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> Poll<Option<Self::Item>> {
        match self.get_mut() {
            ListenerType::BatteryState(s) => {
                if let Poll::Ready(Some(s)) = s.poll_next_unpin(cx) {
                    return Poll::Ready(Some(WeakStateType::BatteryState(s)));
                }
            }
            ListenerType::BatteryPercentage(s) => {
                if let Poll::Ready(Some(s)) = s.poll_next_unpin(cx) {
                    return Poll::Ready(Some(WeakStateType::BatteryPercentage(s)));
                }
            }
            ListenerType::BatteryRate(s) => {
                if let Poll::Ready(Some(s)) = s.poll_next_unpin(cx) {
                    return Poll::Ready(Some(WeakStateType::BatteryRate(s)));
                }
            }
            ListenerType::ChargeControl(s) => {
                if let Poll::Ready(Some(s)) = s.poll_next_unpin(cx) {
                    return Poll::Ready(Some(WeakStateType::ChargeControl(s)));
                }
            }
            ListenerType::PowerProfile(s) => {
                if let Poll::Ready(Some(s)) = s.poll_next_unpin(cx) {
                    return Poll::Ready(Some(WeakStateType::PowerProfile(s)));
                }
            }
            ListenerType::SuperGFXPower(s) => {
                if let Poll::Ready(Some(_)) = s.poll_next_unpin(cx) {
                    return Poll::Ready(Some(WeakStateType::SuperGFXPower));
                }
            }
        }
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
}

/// The type for a zbus proxy
#[derive(strum_macros::EnumDiscriminants, strum_macros::Display)]
pub enum ProxyType<'a> {
    Upower(upower::xmlgen::DeviceProxy<'a>),
    PowerProfile(power_profiles::xmlgen::PowerProfilesProxy<'a>),
    AsusD(asusd::xmlgen::DaemonProxy<'a>),
    // SuperGFX(supergfxd::SuperGfxProxyOptions<'a>),
}
/// The type for an icon
pub type Icon<'a> = &'a str;

// #[derive(Debug, Default, Clone, Hash)]
// pub struct Icon<'a> {
//     v: Cow<'a, str>,
// }
// impl<'a> Icon<'a> {
//     pub fn new(v: &'a str) -> Self {
//         Self {
//             v: Cow::Borrowed(v),
//         }
//     }
//     pub fn to_string_lossy(&self) -> Cow<'a, str> {
//         self.v
//     }
//     // pub fn to_string(&self)
// }
// impl<'a> std::fmt::Display for Icon<'a> {
//     fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
//         write!(f, "{}", self.v)
//     }
// }

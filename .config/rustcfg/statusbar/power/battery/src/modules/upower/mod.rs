use super::*;
use futures::StreamExt;
use serde::{Deserialize, Serialize};
use smart_default::SmartDefault;
use tracing::{debug, error, warn};
use zbus::zvariant;
pub mod xmlgen;

pub struct UpowerModule<'a> {
    pub proxy: xmlgen::DeviceProxy<'a>,
    pub state: BatteryState,
    pub percent: Percent,
    pub rate: f64,
    pub state_listener: zbus::PropertyStream<'a, BatteryState>,
    pub percent_listener: zbus::PropertyStream<'a, Percent>,
    pub rate_listener: zbus::PropertyStream<'a, f64>,
}
impl<'a> StaticModule for UpowerModule<'a> {
    #[inline]
    fn name(&self) -> &str {
        "UPower"
    }
    #[inline]
    fn mod_type(&self) -> ModuleType {
        ModuleType::Dbus
    }
    #[tracing::instrument(skip(self, ipc))]
    async fn update_server(&self, ipc: &IpcCh) -> ModResult<()> {
        let data = UPowerStatus::new(self.state, self.percent, self.rate);
        ipc.send(StateType::UPower(data)).await?;
        Ok(())
    }
}
impl<'a> DbusModule<'a> for UpowerModule<'a> {
    #[tracing::instrument(skip(connection))]
    async fn new(connection: &zbus::Connection) -> ModResult<Self> {
        let proxy = xmlgen::DeviceProxy::new(connection).await?;
        let (state, percent, rate, state_listener, percent_listener, rate_listener) = tokio::join!(
            proxy.state(),
            proxy.percentage(),
            proxy.energy_rate(),
            proxy.receive_state_changed(),
            proxy.receive_percentage_changed(),
            proxy.receive_energy_rate_changed()
        );
        Ok(Self {
            proxy,
            state: state?,
            percent: percent?,
            rate: rate?,
            state_listener,
            percent_listener,
            rate_listener,
        })
    }
}
impl<'a> Module for UpowerModule<'a> {
    #[tracing::instrument(skip(self))]
    async fn update(&mut self, payload: RecvType) -> ModResult<()> {
        match payload {
            RecvType::BatteryState(state) => {
                self.state = state;
            }
            RecvType::Percent(percent) => {
                self.percent = percent;
            }
            RecvType::Float(rate) => {
                self.rate = rate;
            }
            _ => {
                let out = format!("Received unknown payload: '{:?}'", payload);
                error!("{}", &out);
                return Err(ModError::UpdateError(out));
            }
        }
        Ok(())
    }
    #[tracing::instrument(skip(self, ipc))]
    async fn run(&mut self, ipc: IpcCh) -> ModResult<()> {
        self.update_server(&ipc).await?;
        loop {
            tokio::select! {
                Some(s) = self.state_listener.next() => {
                    if let Ok(p) = s.get().await {
                        if self.update(RecvType::BatteryState(p)).await.is_ok() {
                            self.update_server(&ipc).await?;
                        }
                    }
                }
                Some(s) = self.percent_listener.next() => {
                    if let Ok(p) = s.get().await {
                        if self.update(RecvType::Percent(p)).await.is_ok() {
                            self.update_server(&ipc).await?;
                        }
                    }
                }
                Some(s) = self.rate_listener.next() => {
                    if let Ok(p) = s.get().await {
                        if self.update(RecvType::Float(p)).await.is_ok() {
                            self.update_server(&ipc).await?;
                        }
                    }
                }
            }
        }
    }
    fn should_run(&self) -> bool {
        true
    }
}

/// A function to format the battery rate as a string in one single way
#[inline]
pub fn rate_fmt(rate: f64) -> String {
    format!("{:.1}W", rate)
}

#[derive(Debug, Default, Clone, Copy, Deserialize, Serialize)]
pub struct UPowerStatus {
    icon: Icon,
    percentage: Percent,
    state: upower::BatteryState,
    rate: f64,
    show_rate: bool,
}
impl FmtModule for UPowerStatus {
    fn stdout(&self) -> String {
        self.to_string()
    }
    fn waybar(&self) -> String {
        let myself = self.to_string();
        let my_state = self.state.to_string();
        let tooltip = format!(
            "Percentage: {}, State: {}, Power drawn: {}",
            self.percentage, &my_state, self.rate
        );
        waybar_fmt(&myself, &myself, &tooltip, &my_state, Some(self.percentage))
    }
}
impl UPowerStatus {
    pub fn get_icon(&self) -> Icon {
        self.icon
    }
    pub fn get_percentage(&self) -> Percent {
        self.percentage
    }
    pub fn get_state(&self) -> upower::BatteryState {
        self.state
    }
    pub fn get_rate(&self) -> Option<String> {
        if self.show_rate {
            Some(rate_fmt(self.rate))
        } else {
            None
        }
    }
    pub fn new(state: BatteryState, percentage: Percent, rate: f64) -> Self {
        let (icon, do_rate) = match state {
            BatteryState::Charging => (
                match percentage.u() {
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
                match percentage.u() {
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
        };
        Self {
            icon,
            percentage,
            state,
            rate,
            show_rate: do_rate && rate != 0.0,
        }
    }
}
impl std::fmt::Display for UPowerStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        {
            if let Some(r) = self.get_rate() {
                write!(f, "{} {} {}", self.icon, self.percentage, r)
            } else {
                write!(f, "{} {}", self.icon, self.percentage)
            }
        }
    }
}

/// The current state of the battery, an enum based on its representation in upower
#[derive(
    Debug,
    Copy,
    Clone,
    PartialEq,
    Eq,
    Default,
    strum_macros::Display,
    zvariant::Type,
    Deserialize,
    Serialize,
)]
pub enum BatteryState {
    Charging,
    Discharging,
    Empty,
    FullyCharged,
    PendingCharge,
    PendingDischarge,
    #[default]
    Unknown,
}
impl From<u32> for BatteryState {
    fn from(value: u32) -> Self {
        debug!("Converting from u32 '{}'", value);
        match value {
            1 => Self::Charging,
            2 => Self::Discharging,
            3 => Self::Empty,
            4 => Self::FullyCharged,
            5 => Self::PendingCharge,
            6 => Self::PendingDischarge,
            _ => {
                warn!("Could not match u32 '{}' to a known BatteryState", value);
                Self::default()
            }
        }
    }
}
impl TryFrom<zvariant::OwnedValue> for BatteryState {
    type Error = ModError;
    fn try_from(value: zvariant::OwnedValue) -> Result<Self, Self::Error> {
        debug!("Trying to convert OwnedValue '{:?}' to a known type", value);
        Ok(if let Some(v) = value.downcast_ref::<u32>() {
            Self::from(*v)
        } else {
            Self::default()
        })
    }
}

/// The config for the UPower module
#[derive(Debug, SmartDefault, Serialize, Deserialize)]
pub struct UPowerConfig {
    /// Enable the module
    #[default(AutoBool::default())]
    enable: AutoBool,
    /// Experimental -- alternative upower path
    #[default("/org/freedesktop/UPower/devices/DisplayDevice")]
    upower_path: String,
}

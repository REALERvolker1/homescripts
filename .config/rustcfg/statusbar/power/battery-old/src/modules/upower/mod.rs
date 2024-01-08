use crate::modules;
use futures::{self, StreamExt};
use std::{fmt, str::FromStr};
use strum_macros::{Display, EnumString};
use tokio;
use zbus;
mod xmlgen;

pub struct Battery<'a> {
    proxy: xmlgen::DeviceProxy<'a>,
    state_stream: zbus::PropertyStream<'a, u32>,
    percent_stream: zbus::PropertyStream<'a, f64>,
    rate_stream: zbus::PropertyStream<'a, f64>,
    pub status: BatteryStatus,
    pub state: BatteryState,
    pub percent: Percent,
    pub rate: f64,
}
impl<'a> modules::Module<'a> for Battery<'a> {
    async fn handle_event(
        &mut self,
        event: modules::PropertyListener<'_>,
    ) -> zbus::Result<Option<()>> {
        let is_changed = match event {
            modules::PropertyListener::BatteryState(p) => {
                self.state = BatteryState::from(p.get().await?);
            }
            modules::PropertyListener::BatteryPercentage(p) => {
                self.percent = Percent::from_f64(p.get().await?);
            }
            modules::PropertyListener::BatteryRate(p) => {
                self.rate = p.get().await?;
            }
            _ => return Ok(None),
        };

        Ok(Some(is_changed))
    }
    async fn handle_next(&mut self) -> zbus::Result<()> {
        while let Some(v) = self.next().await {
            self.handle_event(v).await?;
        }
        Ok(())
    }
}

impl<'a> futures::Stream for Battery<'a> {
    type Item = modules::PropertyListener<'a>;
    fn poll_next(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        if let std::task::Poll::Ready(v) = self.state_stream.poll_next_unpin(cx) {
            if let Some(p) = v {
                return std::task::Poll::Ready(Some(modules::PropertyListener::BatteryState(p)));
            }
        }
        if let std::task::Poll::Ready(v) = self.percent_stream.poll_next_unpin(cx) {
            if let Some(p) = v {
                return std::task::Poll::Ready(Some(modules::PropertyListener::BatteryPercentage(
                    p,
                )));
            }
        }
        if let std::task::Poll::Ready(v) = self.rate_stream.poll_next_unpin(cx) {
            if let Some(p) = v {
                return std::task::Poll::Ready(Some(modules::PropertyListener::BatteryRate(p)));
            }
        }
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
}
impl<'a> modules::ModuleExt<'a> for Battery<'a> {
    fn get_state_string(&self, output_type: modules::OutputType) -> String {
        let state = self.state.to_string();
        let rate = self.rate;

        match output_type {
            modules::OutputType::Stdout => {
                format!("{} {:.2} W", state, rate)
            }
            modules::OutputType::Waybar => {
                format!("WAYBAR, CHANGE ME PLEASE: {} {:.2} W", state, rate)
            }
        }
    }
    async fn refresh_state(&mut self) -> zbus::Result<()> {
        let (state, percent, rate) = Self::refresh_proxy(&self.proxy).await?;
        self.state = state;
        self.percent = percent;
        self.rate = rate;

        Ok(())
    }
    /// Create a new instance of battery
    async fn new(connection: &zbus::Connection) -> zbus::Result<modules::Property<'a>> {
        let proxy = xmlgen::DeviceProxy::new(connection).await?;

        let (state, percent, rate) = Self::refresh_proxy(&proxy).await?;

        let (state_stream, percent_stream, rate_stream) = tokio::join!(
            proxy.receive_state_changed(),
            proxy.receive_percentage_changed(),
            proxy.receive_energy_rate_changed()
        );

        let status = BatteryStatus::new(state, percent);

        Ok(modules::Property::Battery(Some(Self {
            proxy,
            state_stream,
            percent_stream,
            rate_stream,
            status,
            state,
            percent,
            rate,
        })))
    }
    fn proptype(&self) -> modules::Property<'a> {
        modules::Property::PowerProfile(None)
    }
}
impl<'a> Battery<'a> {
    async fn refresh_proxy(
        proxy: &xmlgen::DeviceProxy<'a>,
    ) -> zbus::Result<(BatteryState, Percent, f64)> {
        let (state_raw, percent_raw, rate) =
            tokio::try_join!(proxy.state(), proxy.percentage(), proxy.energy_rate())?;
        Ok((
            BatteryState::from(state_raw),
            Percent::from_f64(percent_raw),
            rate,
        ))
    }
}

#[derive(Debug, Copy, PartialEq, Eq, PartialOrd, Ord, Clone, Default)]
pub struct Percent {
    pub inner: u8,
}
impl Percent {
    pub fn from_f64(value: f64) -> Self {
        Self {
            inner: value.round() as u8,
        }
    }
}

/// The current state of the battery, an enum based on its representation in upower
#[derive(Debug, Copy, Clone, PartialEq, Default, Display)]
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
        match value {
            1 => Self::Charging,
            2 => Self::Discharging,
            3 => Self::Empty,
            4 => Self::FullyCharged,
            5 => Self::PendingCharge,
            6 => Self::PendingDischarge,
            _ => Self::Unknown,
        }
    }
}
impl FromStr for BatteryState {
    type Err = fmt::Error;
    fn from_str(s: &str) -> Result<Self, fmt::Error> {
        Ok(match s.to_lowercase().trim() {
            "charging" => Self::Charging,
            "discharging" => Self::Discharging,
            "empty" => Self::Empty,
            "fullycharged" => Self::FullyCharged,
            "pendingcharge" => Self::PendingCharge,
            "pendingdischarge" => Self::PendingDischarge,
            _ => Self::Unknown,
        })
    }
}

type IsCharging = bool;

/// The status of the battery, mainly meant for dtermining what icon to show
#[derive(Debug, Copy, Clone, PartialEq, Default)]
pub enum BatteryStatus {
    Charging(Percent),
    Discharging(Percent),
    /// Pending charge or discharge, bool true means charge, bool false means discharge
    Pending(IsCharging),
    FullyCharged,
    #[default]
    Empty,
}

impl BatteryStatus {
    pub fn new(state: BatteryState, percent: Percent) -> Self {
        match state {
            BatteryState::Charging => Self::Charging(percent),
            BatteryState::Discharging => Self::Discharging(percent),
            BatteryState::PendingCharge => Self::Pending(true),
            BatteryState::PendingDischarge => Self::Pending(false),
            BatteryState::FullyCharged => Self::FullyCharged,
            _ => Self::Empty,
        }
    }
    /// Retrieve the hardcoded icon for this type
    pub fn icon(&self) -> modules::Icon {
        match self {
            BatteryStatus::Charging(p) => match p.inner {
                101.. => "󰂏?",
                95.. => "󰂅",
                91.. => "󰂋",
                81.. => "󰂊",
                71.. => "󰢞",
                61.. => "󰂉",
                51.. => "󰢝",
                41.. => "󰂈",
                31.. => "󰂇",
                21.. => "󰂆",
                11.. => "󰢜",
                _ => "󰢟",
            },
            BatteryStatus::Discharging(p) => match p.inner {
                101.. => "󰂌?",
                95.. => "󰁹",
                91.. => "󰂂",
                81.. => "󰂁",
                71.. => "󰂀",
                61.. => "󰁿",
                51.. => "󰁾",
                41.. => "󰁽",
                31.. => "󰁼",
                21.. => "󰁻",
                11.. => "󰁺",
                _ => "󰂎",
            },
            BatteryStatus::Empty => "󱟩",
            BatteryStatus::FullyCharged => "󰂄",
            BatteryStatus::Pending(is_charging) => {
                if *is_charging {
                    "󰂏"
                } else {
                    "󰂌"
                }
            }
        }
    }
}

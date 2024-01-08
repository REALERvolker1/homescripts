use crate::modules;
use futures::StreamExt;
mod asusd_xmlgen;
mod xmlgen;

pub struct BatteryProxy<'a> {
    pub proxy: xmlgen::DeviceProxy<'a>,
    pub state_stream: zbus::PropertyStream<'a, u32>,
    pub percent_stream: zbus::PropertyStream<'a, f64>,
    pub rate_stream: zbus::PropertyStream<'a, f64>,
    pub asusd_proxy: Option<asusd_xmlgen::DaemonProxy<'a>>,
    pub charge_control_stream: Option<zbus::PropertyStream<'a, u8>>,
}
impl<'a> modules::Proxy<'a> for BatteryProxy<'a> {}
impl<'a> BatteryProxy<'a> {
    pub async fn new(
        connection: &'a zbus::Connection,
        charge_control: Option<Percent>,
    ) -> Option<(crate::modules::PropertyProxy, crate::modules::Property)> {
        let proxy = if let Ok(p) = xmlgen::DeviceProxy::new(connection).await {
            p
        } else {
            return None;
        };

        let (asusd_proxy, charge_control_stream, charge_control_end) =
            if let Ok(a) = Self::with_asusd(connection).await {
                (Some(a.0), Some(a.1), a.2)
            } else {
                (None, None, 0)
            };

        let status = if let Ok(s) =
            tokio::try_join!(proxy.state(), proxy.percentage(), proxy.energy_rate())
        {
            modules::Property::Battery(
                BatteryStatus::from_raw(s.0, s.1, s.2, charge_control_end).unwrap_or_default(),
            )
        } else {
            return None;
        };

        let (state_stream, percent_stream, rate_stream) = tokio::join!(
            proxy.receive_state_changed(),
            proxy.receive_percentage_changed(),
            proxy.receive_energy_rate_changed()
        );

        Some((
            modules::PropertyProxy::Battery(Self {
                proxy,
                state_stream,
                percent_stream,
                rate_stream,
                asusd_proxy,
                charge_control_stream,
            }),
            status,
        ))
    }
    /// Tries to set up an asusd listener, returns current charge control end state
    async fn with_asusd(
        connection: &zbus::Connection,
    ) -> zbus::Result<(asusd_xmlgen::DaemonProxy, zbus::PropertyStream<u8>, Percent)> {
        let asus_proxy = asusd_xmlgen::DaemonProxy::new(connection).await?;
        let (charge_control, listener) = tokio::join!(
            asus_proxy.charge_control_end_threshold(),
            asus_proxy.receive_charge_control_end_threshold_changed()
        );

        Ok((asus_proxy, listener, charge_control?))
    }
}

impl<'a> futures::Stream for BatteryProxy<'a> {
    type Item = modules::WeakStateType<'a>;
    fn poll_next(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        if let std::task::Poll::Ready(Some(v)) = self.state_stream.poll_next_unpin(cx) {
            return std::task::Poll::Ready(Some(modules::WeakStateType::BatteryState(v)));
        }
        if let std::task::Poll::Ready(Some(v)) = self.percent_stream.poll_next_unpin(cx) {
            return std::task::Poll::Ready(Some(modules::WeakStateType::BatteryPercentage(v)));
        }
        if let std::task::Poll::Ready(Some(v)) = self.rate_stream.poll_next_unpin(cx) {
            return std::task::Poll::Ready(Some(modules::WeakStateType::BatteryRate(v)));
        }
        if let Some(charge_stream) = &mut self.charge_control_stream {
            if let std::task::Poll::Ready(Some(v)) = charge_stream.poll_next_unpin(cx) {
                return std::task::Poll::Ready(Some(modules::WeakStateType::ChargeControl(v)));
            }
        }
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
}

/// Additional rules to determine which power states to show colors for on my waybar
#[derive(Debug, Copy, Clone, PartialEq, Eq, Default, strum_macros::Display)]
pub enum BatteryCondition {
    /// When it is at the asusctl charge control threshold (charging limit)
    ChargeControlThreshold,
    /// When the machine is drawing a lot of power (configurable)
    HighDraw,
    /// When there isn't a lot of juice left
    LowPower,
    /// Everything is okay
    Clear,
    /// None, will be updated on demand
    #[default]
    None,
}

/// The current state of the battery, an enum based on its representation in upower
#[derive(Debug, Copy, Clone, PartialEq, Eq, Default, strum_macros::Display)]
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
impl BatteryState {
    #[inline]
    pub fn from_u32(value: u32) -> Option<Self> {
        match value {
            1 => Some(Self::Charging),
            2 => Some(Self::Discharging),
            3 => Some(Self::Empty),
            4 => Some(Self::FullyCharged),
            5 => Some(Self::PendingCharge),
            6 => Some(Self::PendingDischarge),
            _ => None,
        }
    }
}

pub type Percent = u8;

#[derive(Debug, Copy, Clone, PartialEq, Default)]
pub struct BatteryStatus {
    pub condition: BatteryCondition,
    pub state: BatteryState,
    pub percent: Percent,
    pub rate: f64,
    pub charge_control_end: Percent,
}
impl BatteryStatus {
    /// Create a new instance from the raw base types. If you have refined types, construct this manually.
    pub fn from_raw(
        state_raw: u32,
        percent_raw: f64,
        rate_raw: f64,
        charge_control: u8,
    ) -> Option<Self> {
        Some(Self {
            condition: BatteryCondition::default(),
            state: BatteryState::from_u32(state_raw)?,
            percent: percent_raw as Percent,
            rate: rate_raw,
            charge_control_end: charge_control,
        })
    }
    /// Get the status
    pub fn status_string(&self) -> String {
        match self.state {
            BatteryState::FullyCharged
            | BatteryState::PendingCharge
            | BatteryState::PendingDischarge => format!("{} {}%", self.icon(), self.percent),
            _ => {
                // TODO: Remove charge_control_end, that's supposed to be part of the css class
                format!(
                    "{} {}% {:.2}W, {:?}",
                    self.icon(),
                    self.percent,
                    self.rate,
                    self.charge_control_end
                )
            }
        }
    }
    fn update_state(&mut self) {}
    /// Retrieve the hardcoded icon for this type
    #[inline]
    fn icon(&self) -> modules::Icon {
        match self.state {
            BatteryState::Charging => match self.percent {
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
            BatteryState::Discharging => match self.percent {
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
            BatteryState::Empty => "󱟩",
            BatteryState::FullyCharged => "󰂄",
            BatteryState::PendingCharge => "󰂏",
            BatteryState::PendingDischarge => "󰂌",
            BatteryState::Unknown => "󱉞?",
        }
    }
}

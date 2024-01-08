use crate::modules;
use futures::StreamExt;
mod xmlgen;

pub struct BatteryProxy<'a> {
    pub proxy: xmlgen::DeviceProxy<'a>,
    pub state_stream: zbus::PropertyStream<'a, u32>,
    pub percent_stream: zbus::PropertyStream<'a, f64>,
    pub rate_stream: zbus::PropertyStream<'a, f64>,
}
impl<'a> modules::Proxy<'a> for BatteryProxy<'a> {
    async fn new(
        connection: &'a zbus::Connection,
    ) -> Option<(crate::modules::PropertyProxy, crate::modules::Property)> {
        let proxy = if let Ok(p) = xmlgen::DeviceProxy::new(connection).await {
            p
        } else {
            return None;
        };

        let (s, p, r, state_stream, percent_stream, rate_stream) = tokio::join!(
            proxy.state(),
            proxy.percentage(),
            proxy.energy_rate(),
            proxy.receive_state_changed(),
            proxy.receive_percentage_changed(),
            proxy.receive_energy_rate_changed()
        );

        // we don't have multiple `if let Ok()` yet
        let status = if s.is_ok() && p.is_ok() && r.is_ok() {
            modules::Property::Battery(
                BatteryStatus::from_raw(s.unwrap(), p.unwrap(), r.unwrap()).unwrap_or_default(),
            )
        } else {
            return None;
        };

        Some((
            modules::PropertyProxy::Battery(Self {
                proxy,
                state_stream,
                percent_stream,
                rate_stream,
            }),
            status,
        ))
    }
    fn name() -> String {
        String::from("battery")
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
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
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
    pub state: BatteryState,
    pub percent: Percent,
    pub rate: f64,
}
impl BatteryStatus {
    /// Create a new instance from the raw base types. If you have refined types, construct this manually.
    pub fn from_raw(state_raw: u32, percent_raw: f64, rate_raw: f64) -> Option<Self> {
        Some(Self {
            state: BatteryState::from_u32(state_raw)?,
            percent: percent_raw as Percent,
            rate: rate_raw,
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
                format!("{} {}% {:.2}W", self.icon(), self.percent, self.rate,)
            }
        }
    }
    pub fn update_state(&mut self, state: modules::StateType) {
        match state {
            modules::StateType::BatteryPercentage(p) => self.percent = p,
            modules::StateType::BatteryRate(p) => self.rate = p,
            modules::StateType::BatteryState(p) => self.state = p,
            _ => (),
        }
    }
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

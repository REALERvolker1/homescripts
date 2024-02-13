mod xmlgen;
use super::*;

#[derive(Debug)]
pub struct UPowerModule<'a> {
    proxy: xmlgen::DeviceProxy<'a>,
    state_stream: PropertyStream<'a, BatteryState>,
    percent_stream: PropertyStream<'a, Percent>,
    rate_stream: PropertyStream<'a, f64>,
    current_data: BatteryStatus,
}
impl<'a> Module for UPowerModule<'a> {
    type StartupData = Arc<Connection>;
    #[tracing::instrument(skip_all, level = "debug")]
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        let proxy = xmlgen::DeviceProxy::new(&data).await?;
        let (init_state, state_stream, percent_stream, rate_stream) = join!(
            Self::get_all(&proxy),
            proxy.receive_state_changed(),
            proxy.receive_percentage_changed(),
            proxy.receive_energy_rate_changed(),
        );
        let state = init_state?;
        let me = Self {
            proxy,
            state_stream,
            percent_stream,
            rate_stream,
            current_data: state,
        };
        Ok((me, state.into()))
    }
    #[tracing::instrument(skip_all, level = "debug")]
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        loop {
            select! {
                Some(s) = self.state_stream.next() => {
                    if let Ok(s) = s.get().await {
                        self.current_data.set_state(s);
                        sender.send(self.current_data.into()).await?;
                    }
                }
                Some(p) = self.percent_stream.next() => {
                    if let Ok(p) = p.get().await {
                        self.current_data.set_percentage(p);
                        sender.send(self.current_data.into()).await?;
                    }
                }
                Some(r) = self.rate_stream.next() => {
                    if let Ok(r) = r.get().await {
                        self.current_data.set_rate(r.into());
                        sender.send(self.current_data.into()).await?;
                    }
                }
            }
        }
    }
}
impl UPowerModule<'_> {
    /// Get all the data
    #[tracing::instrument(skip_all, level = "debug")]
    pub async fn get_all(proxy: &xmlgen::DeviceProxy<'_>) -> ModResult<BatteryStatus> {
        let (state, percent, rate) =
            try_join!(proxy.state(), proxy.percentage(), proxy.energy_rate(),)?;
        Ok(BatteryStatus::new(state, percent, rate.into()))
    }
    #[inline]
    pub async fn update_all(&mut self) -> ModResult<()> {
        self.current_data = Self::get_all(&self.proxy).await?;
        Ok(())
    }
}

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
    #[tracing::instrument(skip_all, level = "debug")]
    pub fn set_rate(mut self, rate: FuckingFloat) {
        self = Self::new(self.state, self.percentage, rate);
    }

    /// Basically just [`BatteryStatus::new`] but using current values
    #[tracing::instrument(skip_all, level = "debug")]
    pub fn set_percentage(mut self, percentage: Percent) {
        self = Self::new(self.state, percentage, self.rate);
    }

    /// Basically just [`BatteryStatus::new`] but using current values
    #[tracing::instrument(skip_all, level = "debug")]
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
    FullyCharged = 4,
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

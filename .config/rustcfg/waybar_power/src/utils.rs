use crate::settings::*;

pub(crate) use dbus::{
    blocking::{
        stdintf::org_freedesktop_dbus::Properties,
        stdintf::org_freedesktop_dbus::PropertiesPropertiesChanged, LocalConnection, Proxy,
    },
    channel::MatchingReceiver,
    message::MatchRule,
    Message,
};
pub use std::{cell::Cell, rc::Rc, time::Duration};

pub type R<T> = ::std::result::Result<T, dbus::Error>;
pub type Conn = LocalConnection;
pub type Icon = char;

pub struct IfaceSettings<'a> {
    pub destination: &'a str,
    pub path: &'a str,
    pub interface: &'a str,
}
impl<'a, 'b> IfaceSettings<'a> {
    pub fn match_rule(&self, member: &'a str) -> MatchRule<'a> {
        // let rule_signal = MatchRule::new_signal(self.interface, self.name).with_path(self.path);
        let rule_prop = MatchRule::new()
            .with_interface(self.interface)
            .with_path(self.path)
            .with_member(member);
        rule_prop
    }

    pub fn proxy(&'a self, conn: &'a Conn) -> Proxy<'a, &'a Conn> {
        conn.with_proxy(self.destination, self.path, QUERY_TIMEOUT)
    }
}

pub struct Config {
    pub discharge_fast_threshold: BatRateType,
    pub discharge_ultra_threshold: BatRateType,
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub enum CssClass {
    /// Done charging
    Charging,
    DischargingGfxActive,
    DischargingLow,
    DischargingFast,
    DischargingUltra,
    #[default]
    Normal,
}
impl CssClass {
    pub const DEFAULT: Self = Self::Normal;
    pub fn derive(state: BatteryState, rate: Option<BatRateType>, gfx_active: bool) -> Self {
        match state {
            BatteryState::Charging => return Self::Charging,
            BatteryState::Empty => return Self::DischargingUltra,
            BatteryState::Discharging => {}
            _ => return Self::Normal,
        }

        if gfx_active {
            return Self::DischargingGfxActive;
        }

        let Some(rate) = rate else {
            return Self::Normal;
        };

        if rate >= CONFIG.discharge_ultra_threshold {
            return Self::DischargingUltra;
        } else if rate >= CONFIG.discharge_fast_threshold {
            return Self::DischargingFast;
        }

        Self::Normal
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub enum BatteryState {
    Charging = 1,
    Discharging = 2,
    Empty = 3,
    FullyCharged = 4,
    PendingCharge = 5,
    PendingDischarge = 6,
    #[default]
    Unknown,
}
impl BatteryState {
    pub const fn from_dbus(state: BatStateType) -> Self {
        match state {
            1 => BatteryState::Charging,
            2 => BatteryState::Discharging,
            3 => BatteryState::Empty,
            4 => BatteryState::FullyCharged,
            5 => BatteryState::PendingCharge,
            6 => BatteryState::PendingDischarge,
            _ => BatteryState::Unknown,
        }
    }
    pub const fn is_plugged(&self) -> bool {
        match self {
            BatteryState::Charging | BatteryState::PendingCharge | BatteryState::FullyCharged => {
                true
            }
            _ => false,
        }
    }
}

pub const fn sgfx_mode_icon(mode: SgfxModeType) -> Option<Icon> {
    let icon = match mode {
        // 0: Hybrid
        1 => '󰰃', // Integrated
        2 => '󰰒', // NvidiaNoModeset
        3 => '󰰪', // Vfio
        4 => '󰯷', // AsusEgpu
        5 => '󰰏', // AsusMuxDgpu
        // 6: Unknown
        _ => return None,
    };

    Some(icon)
}
/*
/// just here for future reference
const fn sgfx_power_icon(power: u32) -> char {
    match power {
        0 => '󰒇', // Active
        1 => '󰒆', // Suspended
        2 => '󰒅', // Off
        3 => '󰒈', // AsusDisabled
        4 => '󰾂', // AsusMuxDiscreet
        _ => '󰳤', // Unknown
    }
}
*/

pub fn battery_icon(state: BatteryState, percentage: u8) -> &'static str {
    match state {
        BatteryState::Charging => match percentage {
            101.. => "󰂏?",
            91.. => "󰂋",
            81.. => "󰂊",
            71.. => "󰢞",
            61.. => "󰂉",
            51.. => "󰢝",
            41.. => "󰂈",
            31.. => "󰂇",
            21.. => "󰂆",
            11.. => "󰢜",
            0.. => "󰢟",
        },
        BatteryState::Discharging => match percentage {
            101.. => "󰂌?",
            91.. => "󰂂",
            81.. => "󰂁",
            71.. => "󰂀",
            61.. => "󰁿",
            51.. => "󰁾",
            41.. => "󰁽",
            31.. => "󰁼",
            21.. => "󰁻",
            11.. => "󰁺",
            0.. => "󰂎",
        },
        BatteryState::Empty => "󱟩",
        BatteryState::FullyCharged => "󰂄",
        BatteryState::PendingCharge => "󰂏",
        BatteryState::PendingDischarge => "󰂌",
        BatteryState::Unknown => "󰂑?",
    }
}

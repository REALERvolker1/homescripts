pub use crate::utils::*;

pub const CONFIG: Config = Config {
    discharge_fast_threshold: 20.0,
    discharge_ultra_threshold: 30.0,
};

pub const EVENT_TIMEOUT: Duration = Duration::from_secs(30);
pub const QUERY_TIMEOUT: Duration = Duration::from_secs(1);

pub const SUPERGFX_IFACE: IfaceSettings = IfaceSettings {
    destination: "org.supergfxctl.Daemon",
    path: "/org/supergfxctl/Gfx",
    interface: "org.supergfxctl.Daemon",
};
pub const SGFX_NOTIFY_GFX_STATUS: &str = "NotifyGfxStatus";
pub const SGFX_MODE: &str = "Mode";
pub const SGFX_POWER: &str = "Power";

pub type SgfxModeType = u32;
pub type SgfxPowerType = u32;

pub const PPROF_IFACE: IfaceSettings = IfaceSettings {
    destination: "org.freedesktop.UPower.PowerProfiles",
    path: "/org/freedesktop/UPower/PowerProfiles",
    interface: "org.freedesktop.UPower.PowerProfiles",
};

pub const PPROF_PROFILE: &str = "ActiveProfile";

pub type PprofType = String;

// alternative, that one may not work on older distros
/*
pub const PPROF_IFACE: IfaceSettings = IfaceSettings {
    destination: "net.hadess.PowerProfiles",
    path: "/net/hadess/PowerProfiles",
    interface: "net.hadess.PowerProfiles",
};
*/

pub const BAT_IFACE: IfaceSettings = IfaceSettings {
    destination: "org.freedesktop.UPower",
    path: "/org/freedesktop/UPower/devices/DisplayDevice",
    interface: "org.freedesktop.UPower.Device",
};
pub const BAT_PERCENT: &str = "Percentage";
pub const BAT_RATE: &str = "EnergyRate";
pub const BAT_STATE: &str = "State";

pub type BatPercentType = f64;
pub type BatRateType = f64;
pub type BatStateType = u32;

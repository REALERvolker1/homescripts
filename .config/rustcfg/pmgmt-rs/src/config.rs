use std::path::PathBuf;

use crate::*;

pub const DUMMY_BRIGHTNESS: u32 = u32::MAX;

pub const BACKLIGHT: &str = "intel_backlight"; // /sys/class/backlight/intel_backlight/max_brightness
pub const BACKLIGHT_PATH: &str = "/sys/class/backlight";

// config
pub const AC_CONFIG: Config = Config {
    brightness: 100,
    keyboard: 4,
    power_profile: "performance",
    panel_overdrive: true,
};
pub const BAT_CONFIG: Config = Config {
    brightness: 50,
    keyboard: 1,
    power_profile: "balanced",
    panel_overdrive: false,
};
pub const BAT_LOW_CONFIG: Config = Config {
    brightness: 20,
    keyboard: 1,
    power_profile: "power-saver",
    panel_overdrive: false,
};
pub const BAT_CRITICAL_CONFIG: Config = Config {
    brightness: 5,
    keyboard: 0,
    power_profile: "power-saver",
    panel_overdrive: false,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum BatteryState {
    Plugged,
    Good,
    Bad,
    Critical,
    #[default]
    Unknown,
}
impl BatteryState {
    pub fn from_percent(percentage: f64) -> Self {
        match percentage as u64 {
            51.. => BatteryState::Good,
            21.. => BatteryState::Bad,
            0.. => BatteryState::Critical,
        }
    }
}

pub struct Config {
    pub brightness: u32,
    pub keyboard: u8,
    pub power_profile: &'static str,
    pub panel_overdrive: bool,
}

/// Get the max brightness for the device
pub async fn get_max_brightness() -> u32 {
    let back_path = PathBuf::from(BACKLIGHT_PATH)
        .join(BACKLIGHT)
        .join("max_brightness");

    match fs::read_to_string(&back_path).await {
        Ok(s) => match s.trim().parse::<u32>() {
            Ok(i) => i,
            Err(e) => {
                println!(
                    "Failed to parse max brightness file string: '{s}' from path {}: {e}",
                    back_path.display()
                );
                DUMMY_BRIGHTNESS
            }
        },
        Err(e) => {
            println!("Failed to read backlight file {}: {e}", back_path.display());
            DUMMY_BRIGHTNESS
        }
    }

    // let out = tmp / 100;
    // Ok(out)
}
// println!("Failed to get max brightness: {e}\nfalling back to {DUMMY_BRIGHTNESS}. Undefined behavior may occur.");

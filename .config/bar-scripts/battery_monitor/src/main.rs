use std::{
    io,
};
use upower_dbus::{self, DeviceProxy, UPowerProxy, BatteryState};
use zbus::{self, export::futures_util::StreamExt};

const UPOWER_BATTERY_DEVICE: &str = "/org/freedesktop/UPower/devices/battery_BAT1";
const SYSFS_BATTERY_DEVICE: &str = "/sys/class/power_supply/BAT1";

#[tokio::main]
async fn main() -> Result<(), zbus::Error> {
    let dbus_connection: zbus::Connection = zbus::Connection::system().await?;
    let device_proxy = upower_dbus::DeviceProxy::new(&dbus_connection, UPOWER_BATTERY_DEVICE).await?;

    let mut percent_cache: f64 = device_proxy.percentage().await?;
    let mut energy_cache: f64 = device_proxy.energy().await?;
    let mut state_cache: upower_dbus::BatteryState = device_proxy.state().await?;

    format_output(&percent_cache, &energy_cache, &state_cache);

    let mut battery_percent_stream = device_proxy.receive_percentage_changed().await;
    let mut battery_energy_stream = device_proxy.receive_energy_changed().await;
    let mut battery_state_stream = device_proxy.receive_state_changed().await;

    loop {
        tokio::select! {
            Some(percent) = battery_percent_stream.next() => {
                let percent_value = percent.get().await?;
                percent_cache = percent_value;
                format_output(&percent_cache, &energy_cache, &state_cache);
            }
            Some(energy) = battery_energy_stream.next() => {
                let energy_value = energy.get().await?;
                energy_cache = energy_value;
                format_output(&percent_cache, &energy_cache, &state_cache);
            }
            Some(state) = battery_state_stream.next() => {
                let state_value = state.get().await?;
                state_cache = state_value;
                format_output(&percent_cache, &energy_cache, &state_cache);
            }
        }
    }

    // Ok(())
}

fn format_output(percent: &f64, energy: &f64, state: &BatteryState) {
    let percent_int: i64 = percent.round() as i64;
    let icon = match state {
        BatteryState::Charging => {
            match percent_int {
                0..=33 => "󱊤",
                34..=66 => "󱊥",
                67..=100 => "󱊦",
                _ => "󰂑"
            }
        },
        BatteryState::Discharging => {
            match percent_int {
                0..=33 => "󱊡",
                34..=66 => "󱊢",
                67..=100 => "󱊣",
                _ => "󰂑"
            }
        }
        BatteryState::FullyCharged => "󰁹",
        BatteryState::Empty => "󱃍",
        BatteryState::PendingCharge => "󰂏",
        BatteryState::PendingDischarge => "󰂌",
        _ => "󰂑",
    };

    println!("{:.1}% {:.2}W {}", percent, energy, icon)
}

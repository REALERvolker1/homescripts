//use futures::StreamExt;
use std::io;
use tokio;
use upower_dbus::{self, DeviceProxy, UPowerProxy};
use zbus::{self, export::futures_util::StreamExt};
//mod utils;

const UPOWER_BATTERY_DEVICE: &str = "/org/freedesktop/UPower/devices/battery_BAT1";
const SYSFS_BATTERY_DEVICE: &str = "/sys/class/power_supply/BAT1";
//const BATTERY_DEVICE: String = String::from("/org/freedesktop/UPower/devices/battery_BAT1");

#[tokio::main]
async fn main() -> Result<(), zbus::Error> {
    // init
    let dbus_connection: zbus::Connection = zbus::Connection::system().await?;
    let device_proxy =
        upower_dbus::DeviceProxy::new(&dbus_connection, UPOWER_BATTERY_DEVICE).await?;

    //init but like getting initial values
    let mut percent_cache: f64 = device_proxy.percentage().await?;
    let mut energy_cache: f64 = device_proxy.energy().await?;
    //let mut voltage_cache: f64 = device_proxy.voltage().await?;
    let mut state_cache: upower_dbus::BatteryState = device_proxy.state().await?;
    format_output(&percent_cache, &energy_cache, &state_cache)?;
    // format_output(&percent_cache, &energy_cache, &voltage_cache, &state_cache)?;

    //stream watch

    let mut battery_percent_stream = device_proxy.receive_percentage_changed().await;
    let mut battery_energy_stream = device_proxy.receive_energy_changed().await;
    //let mut battery_voltage_stream = device_proxy.receive_voltage_changed().await;
    let mut battery_state_stream = device_proxy.receive_state_changed().await;

    loop {
        tokio::select! {
            Some(percent) = battery_percent_stream.next() => {
                let percent_value = percent.get().await?;
                // println!("Percentage Change: {}", &percent_value);
                percent_cache = percent_value;
                format_output(&percent_cache, &energy_cache, &state_cache)?;
            }
            Some(energy) = battery_energy_stream.next() => {
                let energy_value = energy.get().await?;
                // println!("Energy Change: {}", energy_value);
                energy_cache = energy_value;
                format_output(&percent_cache, &energy_cache, &state_cache)?;
            }
            Some(state) = battery_state_stream.next() => {
                let state_value = state.get().await?;
                // println!("State Change: {:#?}", &state_value);
                state_cache = state_value;
                format_output(&percent_cache, &energy_cache, &state_cache)?;
            }
            /*
            Some(voltage) = battery_voltage_stream.next() => {
                let voltage_value = voltage.get().await?;
                println!("State Change: {:#?}", &voltage_value);
                voltage_cache = voltage_value;
                format_output(&percent_cache, &energy_cache, &state_cache)?;
            }
            */
        }
    }
    Ok(())
}

fn format_output(
    percent: &f64,
    energy: &f64,
    state: &upower_dbus::BatteryState,
) -> Result<(), io::Error> {
    let output = format!("{}% {}W*h {:#?}", percent, energy, state);
    println!("{}", output);
    Ok(())
}

fn get_current(energy: &f64, voltage: &f64) -> f64 {
    return (energy * voltage) / 1_000_000.0;
}

fn get_icon(level: u8, charging: bool) -> &'static str {
    // yoink https://github.com/greshake/i3status-rust/blob/master/src/util.rs#L80
    match (level, charging) {
        (_, true) => "bat_charging",
        (0..=10, _) => "bat_10",
        (11..=20, _) => "bat_20",
        (21..=30, _) => "bat_30",
        (31..=40, _) => "bat_40",
        (41..=50, _) => "bat_50",
        (51..=60, _) => "bat_60",
        (61..=70, _) => "bat_70",
        (71..=80, _) => "bat_80",
        (81..=90, _) => "bat_90",
        _ => "bat_full",
    }
}

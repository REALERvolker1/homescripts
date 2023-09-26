use std::env;
use zbus::{
    self,
    export::futures_util::StreamExt,
};

mod types;

const HARDCODED_BATTERY_PATH: &str = "/org/freedesktop/UPower/devices/battery_BAT1";
const HARDCODED_PRINT_TYPE: &str = "waybar";

#[tokio::main]
async fn main() -> Result<(), zbus::Error> {
    // argparse();
    let battery_path = HARDCODED_BATTERY_PATH;

    let dbus_connection: zbus::Connection = zbus::Connection::system().await?;
    let upower_proxy = types::UPowerProxy::new(&dbus_connection).await?;

    let battery_proxy: types::DeviceProxy;
    if battery_path.is_empty() {
        battery_proxy = upower_proxy.get_display_device().await?;
    } else {
        battery_proxy = types::DeviceProxy::builder(&dbus_connection)
        .cache_properties(zbus::CacheProperties::Yes)
        .path(battery_path)?
        .build().await?;

        let battery_type = battery_proxy.type_().await?;
        if battery_type != types::BatteryType::Battery {
            panic!("Detected battery type `{:?}`, this currently only works with battery type of `{:?}`", battery_type, types::BatteryType::Battery)
        }
    }

    let print_sel = HARDCODED_PRINT_TYPE;
    let print_type: types::PrintType = match print_sel {
        "waybar" => types::PrintType::Waybar,
        "json" => types::PrintType::JSON,
        "simple" => types::PrintType::Simple,
        "complex" => types::PrintType::Complex,
        _ => types::PrintType::Complex,
    };

    let initially_is_charging: bool;
    if upower_proxy.on_battery().await? {
        initially_is_charging = false
    }
    else {
        initially_is_charging = true
    }



    let mut battery = types::Battery {
        print_type: print_type,
        charging: initially_is_charging,
        percentage: battery_proxy.percentage().await?.round() as i64,
        energy_rate: battery_proxy.energy_rate().await?,
        state: battery_proxy.state().await?,
        icon: "",
    };
    battery.update_icon();
    battery.print();

    let mut on_battery_stream = upower_proxy.receive_on_battery_changed().await;
    let mut percentage_stream = battery_proxy.receive_percentage_changed().await;
    let mut rate_stream = battery_proxy.receive_energy_rate_changed().await;
    let mut state_stream = battery_proxy.receive_state_changed().await;

    loop {
        tokio::select! {
            Some(on_battery) = on_battery_stream.next() => {
                if on_battery.get().await? {
                    battery.charging = false
                }
                else {
                    battery.charging = true
                }
                battery.update_icon();
                battery.print();
            }
            Some(percentage) = percentage_stream.next() => {
                battery.percentage = percentage.get().await?.round() as i64;
                battery.update_icon();
                battery.print();
            }
            Some(rate) = rate_stream.next() => {
                battery.energy_rate = rate.get().await?;
                battery.print();
            }
            Some(state) = state_stream.next() => {
                battery.state = state.get().await?;
                battery.update_icon();
                battery.print();
            }
        }
    }
}

// vim ~cfg/bar-scripts/battery_monitor/src/main.rs

// fn calculate_wattage(voltage: f64, energy: f64) -> f64 {
//     (voltage * energy) / 1_000_000_000_000.0
// }

fn argparse() -> () {
    for arg in env::args().skip(1) {
        println!("passed arg {}", arg)
    }
}

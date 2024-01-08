use futures::StreamExt;
use std::collections::{HashMap, HashSet};
mod config;
mod modules;
use crate::modules::*;

/// The main entry point
///
/// It is single-threaded to use less system resources, as raw speed is not as important in this program.
#[tokio::main(flavor = "current_thread")]
async fn main() -> zbus::Result<()> {
    let init = tokio::join!(
        config::get_config(),
        zbus::ConnectionBuilder::system()?.build()
    );
    let config = init.0;
    let connection = init.1?;

    // load modules
    let (mut global_state, mut listeners) = load_modules(&connection, config).await;

    if listeners.len() == 0 {
        eprintln!("No modules to listen to!");
        return Ok(());
    }
    // } else {
    //
    // }

    eprintln!(
        "Listening to modules: {}",
        listeners
            .iter()
            .map(|i| i.to_string())
            .collect::<Vec<_>>()
            .join(", ")
    );
    let mut futes = futures::stream::select_all(listeners);

    while let Some(v) = futes.next().await {
        if let Ok(state) = modules::StateType::from_weak(v).await {
            eprintln!("State updated: {:?}", state);
            if let Some(updated) = global_state.update(state) {
                if updated {
                    println!("\nSuccessfully updated\n");
                    global_state.print();
                }
            }
            eprintln!("{:#?}", global_state);
        }
    }

    Ok(())
}

async fn load_modules(
    connection: &zbus::Connection,
    config: config::Config,
) -> (modules::PropertyStore, Vec<modules::PropertyProxy>) {
    let mut global_state = modules::PropertyStore::new();
    let mut listeners = Vec::new();

    let bat_threshold = if config.charge_end_threshold == u8::MAX {
        None
    } else {
        Some(config.charge_end_threshold)
    };

    let (battery, power_profile) = tokio::join!(
        modules::upower::BatteryProxy::new(&connection),
        modules::power_profiles::PowerProfileProxy::new(&connection),
    );

    if let Some(b) = battery {
        listeners.push(b.0);
        global_state.insert_property(b.1);
        // The following only really makes sense if there was a battery
        if let Some(a) = modules::asusd::AsusdProxy::new(&connection).await {
            listeners.push(a.0);
        }
    }
    if let Some(b) = power_profile {
        listeners.push(b.0);
        global_state.insert_property(b.1);
    }

    (global_state, listeners)
}

// /// Sort of a proof-of-concept. Not how I'm designing this project
// async fn battery(connection: &zbus::Connection) -> zbus::Result<()> {
//     let battery_proxy = xmlgen::battery::DeviceProxy::new(&connection).await?;

//     let mut percent_stream = battery_proxy.receive_percentage_changed().await;
//     let mut state_stream = battery_proxy.receive_state_changed().await;
//     let mut rate_stream = battery_proxy.receive_energy_rate_changed().await;

//     loop {
//         tokio::select! {
//             Some(percent_change) = percent_stream.next() => {
//                 if let Ok(p) = percent_change.get().await {
//                     println!("Battery level: {}%", p.round() as u8);
//                 }
//             }
//             Some(state_change) = state_stream.next() => {
//                 if let Ok(s) = state_change.get().await {
//                     println!("Battery state: {:?}", s);
//                 }
//             }
//             Some(rate_change) = rate_stream.next() => {
//                 if let Ok(r) = rate_change.get().await {
//                     println!("Battery rate: {} W", r);
//                 }
//             }
//         }
//     }

//     Ok(())
// }

// macro_rules! sleep {
//     () => {
//         tokio::time::sleep(std::time::Duration::from_secs(10)).await
//     };
//     ($time:expr) => {
//         tokio::time::sleep(std::time::Duration::from_secs($time)).await
//     };
// }

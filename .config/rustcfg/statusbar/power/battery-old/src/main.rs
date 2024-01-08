use futures::StreamExt;

mod modules;
use crate::modules::*;

/// The main entry point
///
/// It is single-threaded to use less system resources, as raw speed is not as important in this program.
#[tokio::main(flavor = "current_thread")]
async fn main() -> zbus::Result<()> {
    let connection = zbus::ConnectionBuilder::system()?.build().await?;
    let output_type = modules::OutputType::Stdout;

    let mut battery = modules::upower::Battery::new(&connection).await?;
    let mut powerprof = modules::power_profiles::PowerProfile::new(&connection).await?;

    let module_list = [battery, powerprof];

    let mut futes = futures::stream::select_all(module_list);

    while let Some(v) = futes.next().await {
        let inner: Option<T> = match v {
            PropertyListener::BatteryPercentage(b) => b.get().await?,
        }
        let prop_type = v.to_proptype();
        futes.iter_mut().for_each(|j| {
            match j.proptype() {
                Property::Battery(Some(b)) => b.handle_event(v).await,
            }
        });
        // futes.iter_mut().for_each(|j| {
        //     let i = j;
        //     async {
        //         match i {
        //             Property::Battery(Some(b)) => b.handle_event(v).await,
        //             Property::PowerProfile(Some(b)) => b.handle_event(v).await,
        //             _ => zbus::Result::Err(zbus::Error::Failure("Invalid Property type".into())),
        //         };
        //     };
        // });
    }

    Ok(())
}

// This is the goal, but I want to iterate through the list of futures, not hardcode each and every module.
// loop {
//     tokio::select! {
//         Some(e) = bat.next() => {
//             bat.handle_event(e).await?;
//         }
//         Some(e) = bat2.next() => {
//             bat2.handle_event(e).await?;
//         }
//         _ = tokio::time::sleep(std::time::Duration::from_secs(1)) => {
//             println!("Checking battery status...");
//         }
//     }
// }

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

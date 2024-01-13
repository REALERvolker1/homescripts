pub mod xmlgen;
use crate::modules::{ListenerType, ProxyType, StateType};
use tracing::{debug, warn};


#[tracing::instrument(skip(connection))]
pub async fn create_power_profiles_module<'a>(
    connection: &zbus::Connection,
) -> zbus::Result<(ProxyType<'a>, StateType, ListenerType<'a>)> {
    debug!("Trying to connect to asusd daemon");
    let daemon_connection = xmlgen::DaemonProxy::new(connection).await;
    let proxy = if let Ok(p) = daemon_connection {
        p
    } else {
        let e = daemon_connection.unwrap_err();
        warn!("Failed to connect to asusd daemon: {}", e);
        return Err(e);
    };

    let (state, state_stream) = tokio::join!(
        proxy.charge_control_end_threshold(),
        proxy.receive_charge_control_end_threshold_changed()
    );
    Ok((
        ProxyType::AsusD(proxy),
        StateType::ChargeControl(state?),
        ListenerType::ChargeControl(state_stream),
    ))
}

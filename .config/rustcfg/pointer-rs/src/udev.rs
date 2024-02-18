use super::*;
use tokio_udev::{AsyncMonitorSocket, EventType, MonitorBuilder};

pub async fn monitor_devices(sender: Sender<()>) -> Res<()> {
    let socket = MonitorBuilder::new()?.match_subsystem_devtype("usb", "usb_device")?;
    let mut monitor: AsyncMonitorSocket = socket.listen()?.try_into()?;

    while let Some(e) = monitor.next().await {
        let event = e?;
        match event.event_type() {
            EventType::Bind | EventType::Unbind | EventType::Unknown => sender.send(()).await?,
            _ => {}
        }
    }
    Ok(())
}

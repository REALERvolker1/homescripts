use crate::{types::*, CONFIG};
use futures::StreamExt;
// use std::io::prelude::*;
use std::sync::Arc;
use tokio::sync::mpsc::Sender;
use tokio_udev::{AsyncMonitorSocket, EventType, MonitorBuilder};

/// This function does not implement Send, because the udev crate ppl are too unsafe
pub async fn monitor_udev(comms: Arc<Sender<()>>) -> PNul {
    let socket_builder = MonitorBuilder::new()?.match_subsystem_devtype("usb", "usb_device")?;

    let mut monitor: AsyncMonitorSocket = socket_builder.listen()?.try_into()?;

    while let Some(event) = monitor.next().await {
        let ev = event?;
        match ev.event_type() {
            EventType::Bind | EventType::Unbind | EventType::Unknown => comms.send(()).await?,
            _ => {}
        }
    }
    Ok(())
}

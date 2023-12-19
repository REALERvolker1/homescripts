use futures::stream::StreamExt;
use log;
use std::io;
use tokio;
use tokio_udev;

pub async fn monitor_devices() -> io::Result<()> {
    // let context = udev::Context::new().unwrap();
    // let monitor = udev::Monitor::new(&context).unwrap();
    // monitor.filter_add_match_subsystem_devtype("block", "disk").unwrap();
    // monitor
    let socket = tokio_udev::MonitorBuilder::new()?
        .match_subsystem("usb")?
        .listen()?;

    let mut monitor_socket = tokio_udev::AsyncMonitorSocket::new(socket)?;

    loop {
        if let Some(res_event) = monitor_socket.next().await {
            log::debug!("{:?}", res_event);
        }
    }

    Ok(())
}

use std::{
    error::Error,
};
use udev;

fn main() -> Result<(), Box<dyn Error>> {
    // let (conn, screen_num) = xcb::Connection::connect(None)?;
    // let setup = conn.get_setup();
    // let screen = setup.roots().nth(screen_num as usize).unwrap();

    // // let input = xinput::get_extension_data(&conn).unwrap();
    // let id = xinput::get_extension_data(&conn).unwrap().first_event;

    // loop {
    //     // conn.flush()?;

    //     println!("Listening for events");
    //     match conn.wait_for_event()? {
    //         xcb::Event::Input(xinput::Event::DeviceChanged(dev)) => {
    //             println!("\nDEVICE STATE\n\n{:?}\n", dev)
    //         },
    //         xcb::Event::Input(xinput::Event::)
    //         _ => {},
    //     }
    //     // println!("received event");
    //     // match event {
    //     //     xcb::Event::Input(xinput::Event::DeviceChanged(event)) => println!("input changed"),
    //     //     _ => continue,
    //     // };
    // }

    let conn = udev::MonitorBuilder::new()?
        .match_subsystem_devtype("usb", "usb_device")?
        .listen()?;

    let next_event = udev::Udev::

    println!("event received");

    Ok(())
}


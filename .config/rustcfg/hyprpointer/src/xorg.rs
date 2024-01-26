use x11rb::{
    connection::RequestConnection,
    protocol::xinput::{self, ConnectionExt, Device},
    rust_connection::RustConnection,
};

use crate::{types::*, *};

#[derive(Debug)]
pub struct Xconnection {
    pub connection: RustConnection,
    pub screen: usize,
}
impl Xconnection {
    pub fn new() -> PResult<Self> {
        let (connection, screen) = x11rb::connect(None)?;
        // if xinput is not available, exit
        if let Err(e) = connection.extension_information(xinput::X11_EXTENSION_NAME) {
            return Err(e.into());
        }

        Ok(Self { connection, screen })
    }
}

pub fn show_xinput(connection: &Xconnection) -> PNul {
    // let devices = xinput::list_input_devices(&connection.connection)?;
    let devices = connection
        .connection
        .xinput_xi_query_device(bool::from(Device::ALL))?;
    let reply = devices.reply()?;
    for device in reply.infos.iter() {
        let name = String::from_utf8_lossy(device.name.as_slice());
        println!("{}", name);
    }
    Ok(())
}

pub fn xinput_get_has_mice(connection: &Xconnection) -> PResult<bool> {
    todo!()
}

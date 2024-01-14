use crate::modules::*;
use zbus::{dbus_interface, Connection};

/// TODO: Give this a better name
pub const APP_ID: &str = "com.github.REALERvolker1.hbar";
pub const APP_ID_PATH: &str = "/com/github/REALERvolker1/hbar";

/// The type for the server, so I don't have to write it everywhere
pub type ServerType = std::sync::Arc<tokio::sync::Mutex<Server>>;

macro_rules! nope {
    () => {
        Err(zbus::fdo::Error::Failed(
            "Invalid property, may not be running".to_owned(),
        ))
    };
}

#[derive(Debug)]
pub struct Server {
    pub ipc: ipc::IpcInterface,
    pub output_type: ipc::OutputType,
    pub upower: Option<upower::UPowerStatus>,
    pub power_profile: Option<power_profiles::PowerProfileState>,
    pub supergfxd_state: Option<String>,
    // pub power_profile_icon: Option<Icon>,
    // pub supergfxd_icon: Option<Icon>,
}
impl Server {
    pub async fn new(ipc: ipc::IpcInterface, output_type: ipc::OutputType) -> Self {
        Self {
            ipc,
            output_type,
            upower: None,
            power_profile: None,
            supergfxd_state: None,
        }
    }
    pub async fn update_upower(&mut self, state: upower::UPowerStatus) {
        let message = state.with_output_type(self.output_type);
        self.upower = Some(state);
        if let Err(e) = self.ipc.send(&message).await {
            tracing::error!("[Server] Failed to send message: {}", e);
        }
    }
    pub async fn power_profile(&mut self, state: power_profiles::PowerProfileState) {
        let message = state.with_output_type(self.output_type);
        self.power_profile = Some(state);
        if let Err(e) = self.ipc.send(&message).await {
            tracing::error!("[Server] Failed to send message: {}", e);
        }
    }
    pub async fn supergfx(&mut self, state: &supergfxd::SuperGfxModule<'_>) {
        let message = state.with_output_type(self.output_type);
        if let Err(e) = self.ipc.send(&message).await {
            tracing::error!("[Server] Failed to send message: {}", e);
        } else {
            self.supergfxd_state = Some(message);
        }
    }
}

// #[dbus_interface(name = "com.github.REALERvolker1.hbar")]
// impl Server {
//     #[dbus_interface(property)]
//     async fn upower(&self) -> zbus::fdo::Result<String> {
//         if let Some(u) = &self.upower {
//             Ok(u.stdout())
//         } else {
//             nope!()
//         }
//     }
//     #[dbus_interface(property)]
//     async fn upower_state(&self) -> zbus::fdo::Result<String> {
//         if let Some(u) = &self.upower {
//             Ok(u.get_state().to_string())
//         } else {
//             nope!()
//         }
//     }
//     #[dbus_interface(property)]
//     async fn power_profile(&self) -> zbus::fdo::Result<String> {
//         if let Some(i) = self.power_profile {
//             Ok(i.to_string())
//         } else {
//             nope!()
//         }
//     }
//     #[dbus_interface(property)]
//     async fn power_profile_icon(&self) -> zbus::fdo::Result<String> {
//         if let Some(i) = self.power_profile_icon {
//             Ok(i.to_string())
//         } else {
//             nope!()
//         }
//     }
//     #[dbus_interface(property)]
//     async fn supergfxd_icon(&self) -> zbus::fdo::Result<String> {
//         if let Some(i) = self.supergfxd_icon {
//             Ok(i.to_string())
//         } else {
//             nope!()
//         }
//     }
// }
// async fn start() -> zbus::Result<ServerType> {
//     let init_server = Server::default();
//     let session_connection = Connection::session().await?;
//     session_connection
//         .object_server()
//         .at(APP_ID_PATH, init_server)
//         .await?;
//     session_connection.Ok(std::sync::Arc::new(tokio::sync::Mutex::new(init_server)))
// }

pub const SERVICE_NAME: &str = "com.github.REALERvolker1.wlservicer";

#[derive(Debug)]
pub struct ServiceHook {
    connection: zbus::Connection,
}
impl ServiceHook {
    pub async fn new() -> Result<Self, ServiceError> {
        let connection = zbus::Connection::session()
            .await
            .map_err(|e| ServiceError::Connection(e))?;

        connection
            .request_name(SERVICE_NAME)
            .await
            .map_err(|e| ServiceError::Registration(e))?;

        Ok(Self { connection })
    }
}
impl Drop for ServiceHook {
    fn drop(&mut self) {
        tokio::runtime::Handle::current()
            .block_on(self.connection.release_name(SERVICE_NAME))
            .expect("Failed to release name");
    }
}

#[derive(Debug, thiserror::Error)]
pub enum ServiceError {
    #[error("Failed to create dbus connection: {0}")]
    Connection(zbus::Error),
    #[error("Failed to register service: {0}")]
    Registration(zbus::Error),
}

// fn run_server(runtime: tokio::runtime::Runtime) ->

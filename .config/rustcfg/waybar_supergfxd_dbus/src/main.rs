pub mod types;
pub mod xmlgen;

use futures_util::StreamExt;
use tokio::io::AsyncWriteExt;

// type E = Box<dyn std::error::Error>;
type E = zbus::Error;

macro_rules! k {
    () => {
        return Ok::<(), E>(());
    };
}

fn main() {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            let conn = zbus::Connection::system().await?;

            let proxy = xmlgen::DaemonProxy::builder(&conn)
                .cache_properties(zbus::proxy::CacheProperties::No)
                .build()
                .await?;

            let mode_query = proxy.mode().await?;

            let mut stdout = tokio::io::stdout();
            macro_rules! writeme {
                ($var:ident) => {
                    stdout.write_all($var.icon().as_bytes()).await?;
                    stdout.flush().await?;
                };
            }

            if let Some(icon) = mode_query.icon() {
                // I don't need to run this anymore
                stdout.write_all(icon.as_bytes()).await?;
                k!();
            }

            let mut subscriber = proxy.receive_notify_gfx_status().await?;

            loop {
                let (_, action) = tokio::join!(subscriber.next(), async {
                    let power = proxy.power().await?;
                    writeme!(power);

                    k!();
                });
                if action.is_err() {
                    return action;
                }
            }
        })
        .unwrap();
}

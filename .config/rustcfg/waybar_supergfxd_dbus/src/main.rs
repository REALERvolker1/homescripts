pub mod types;
pub mod xmlgen;

use futures_lite::StreamExt;

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

            if let Some(icon) = mode_query.icon() {
                // I don't need to run this anymore
                println!("{{\"text\": \"{icon}\"}}");
                k!();
            }

            let mut subscriber = proxy.receive_notify_gfx_status().await?;

            loop {
                futures_lite::future::zip(subscriber.next(), async {
                    let power = proxy.power().await.unwrap();

                    println!(
                        "{{\"text\": \"{}\", \"class\": \"{:?}\"}}\n",
                        power.icon(),
                        power
                    );
                })
                .await;
            }
        })
        .unwrap();
}

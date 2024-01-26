mod backend;
mod cleanup;
mod cli;
mod config;
mod hypr;
mod types;
mod udev;
mod xorg;

use lazy_static::lazy_static;

lazy_static! {
    pub static ref CONFIG: config::Config = config::Config::new_blocking();
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> types::PNul {
    if CONFIG.action.is_locking() {
        tokio::spawn(async move {
            if let Err(e) = cleanup::cleanup_handles().await {
                println!("Error received in cleanup: {e}")
            }
        });
    }
    CONFIG.exec().await?;
    Ok(())
}

// let argparse = cli_new::Overrides::from_args();
// let backend = backend::Backend::default();

// let conf = config::Config::new()
//     .await?
//     .into_device_config(&backend)
//     .await?;
// println!("{:#?}", conf);
// async fn run() -> types::PNul {
//     if CONFIG.backend.is_xorg() {
//         let conn = xorg::Xconnection::new()?;
//         xorg::show_xinput(&conn)?;
//         unimplemented!()
//     }
//     if CONFIG.command.is_locking() {
//         tokio::spawn(async move {
//             if let Err(e) = cleanup::cleanup_handles().await {
//                 println!("Error received in cleanup: {e}")
//             }
//         });
//     }
//     CONFIG.exec().await?;
//     Ok(())
// }

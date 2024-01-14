//! TODO: Add named pipe output
//! TODO: Add clap argparsing
//! TODO: Add logfile output
use crate::{modules::*, types::*, *};
use futures::{FutureExt, StreamExt};
use tracing::{debug, info, warn};

pub const TIMEOUT: std::time::Duration = std::time::Duration::from_secs(30);

#[inline]
pub async fn run_experimental() -> color_eyre::Result<()> {
    #[cfg(debug_assertions)]
    log_init();

    // let config = config::ModuleConfig::default();

    info!("Starting up");

    let (connection, ipc_interface) =
        tokio::join!(zbus::Connection::system(), ipc::IpcInterface::new(2));
    info!("connected to dbus, loaded IPC interface");

    let output_type = ipc::OutputType::Stdout;

    let server = std::sync::Arc::new(tokio::sync::Mutex::new(
        dbus_server::Server::new(ipc_interface?, output_type).await,
    ));

    let mods = modules::load_modules(&connection?, &server).await?;

    info!("Loaded {} modules", mods.len());

    // mods.iter().for_each(|m| {
    //     if m.is_finished() {
    //         if let Err(e) = r {
    //                 warn!("Error in module: {}", e)
    //             }
    //     }
    //     tokio::time::sleep(TIMEOUT).await;
    // });
    loop {
        std::future::pending::<()>().await
    }

    Ok(())
}

#[cfg(debug_assertions)]
pub fn log_init() {
    eprintln!("Initializing logging for debug build");
    // let env_logging = EnvFilter::from_default_env();
    tracing_subscriber::fmt()
        .with_ansi(true)
        .with_file(true)
        .with_level(true)
        .with_line_number(true)
        .with_span_events(tracing_subscriber::fmt::format::FmtSpan::NEW)
        .with_target(true)
        .with_writer(std::io::stderr)
        .with_thread_ids(true)
        .init();
    info!("Logging initialized");
}

// let ipc = Arc::new(ipc::IpcInterface::new(2).await?);
//     println!("yo");
//     let mut tasks = tokio::task::JoinSet::new();
//     for i in 1..6 {
//         tasks.spawn(task_test(
//             i,
//             format!("test message {}", i),
//             Arc::clone(&ipc),
//         ));
//     }
//     while let Some(t) = tasks.join_next().await {
//         println!("task done: {:?}", t);
//     }
// #[tracing::instrument]
// async fn task_test(thread_id: u8, message: String, ipc_interface: Arc<ipc::IpcInterface>) {
//     loop {
//         println!("Sending message from thread {thread_id}");
//         ipc_interface.send(&message).await.unwrap();
//         tokio::time::sleep(std::time::Duration::from_secs(5)).await;
//     }
// }

use crate::{modules::*, types::*, *};
use std::sync::Arc;
use tracing::{debug, info, warn};

/// The default timeout for asyncs
pub const TIMEOUT: std::time::Duration = std::time::Duration::from_secs(30);

/// The max amount of messages that can be queued before they are dropped
pub const BUFFER_SIZE: usize = 10;

#[inline]
pub async fn run() -> eyre::Result<()> {
    #[cfg(debug_assertions)]
    log_init();

    info!("Starting up");

    let connection = zbus::Connection::system().await?;
    let (tx, mut rx) = tokio::sync::mpsc::channel(5);
    let sender = Arc::new(tx);
    info!("connected to dbus, loaded IPC interface");

    let mods = modules::load_modules(&connection, &sender).await?;

    info!("Loaded {} modules", mods.len());

    while let Some(r) = rx.recv().await {
        println!("{}", r.with_output_type(config::ARGS.output_type));
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

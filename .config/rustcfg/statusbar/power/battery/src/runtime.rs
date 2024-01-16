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
    let (tx, mut rx) = tokio::sync::mpsc::channel(BUFFER_SIZE);
    let sender = Arc::new(tx);
    info!("connected to dbus, loaded IPC interface");

    let mods = modules::load_modules(&connection, &sender).await?;

    info!("Loaded {} modules", mods.len());

    let output_type = config::ARGS.output_type;
    while let Some(r) = rx.recv().await {
        let stype = StateTypeDiscriminants::from(&r);
        let message = match r {
            StateType::UPower(s) => s.with_output_type(output_type),
            StateType::PowerProfiles(s) => s.with_output_type(output_type),
            StateType::SuperGfxd(s) => s.with_output_type(output_type),
            StateType::Memory(s) => s,
            StateType::Anonymous(s) => s,
        };

        println!("{:?} {}", stype, message);
    }

    Ok(())
}

/// Initialize a global logger
///
/// This should only be used in debug builds
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

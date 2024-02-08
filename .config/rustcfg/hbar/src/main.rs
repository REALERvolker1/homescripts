use hbar::*;
use tracing_log::AsTrace;

#[tokio::main]
async fn main() -> simple_eyre::Result<()> {
    simple_eyre::install()?;

    let cfg = config::Config::parse();

    let filter = cfg.verbose.log_level_filter();

    tracing_subscriber::fmt()
        .with_max_level(filter.as_trace())
        .with_ansi(true)
        .with_file(true)
        .with_level(true)
        .with_line_number(true)
        .with_span_events(tracing_subscriber::fmt::format::FmtSpan::NEW)
        .with_target(true)
        .with_thread_ids(true)
        .with_writer(std::io::stderr)
        .init();

    info!("Config file contents:\n{}", &cfg);

    module_event_loop().await?;

    Ok(())
}

/// The backend event loop for all the modules. This will "block" the async task thread it is run on.
#[tracing::instrument]
async fn module_event_loop() -> simple_eyre::Result<()> {
    let args = config::Config::parse();

    let (tx, mut rx) = mpsc::channel(128);
    let sender = Arc::new(tx);

    let modules = modules::Modules::new(Arc::clone(&sender), args).await?;

    // TODO: Validation and stuff, set up gtk settings, etc.

    modules.run(Arc::clone(&sender)).await?;

    while let Some(m) = rx.recv().await {
        info!("{}", &m);
        // TODO: Do something with it
    }
    Ok(())
}

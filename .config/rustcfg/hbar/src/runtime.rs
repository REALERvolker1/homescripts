use tracing_subscriber::prelude::*;

use crate::*;

#[cfg(debug_assertions)]
macro_rules! debugging_env {
    () => {
        env::set_var("G_MESSAGES_DEBUG", "all");
        env::set_var("RUST_BACKTRACE", "full");
        env::set_var("COLORBT_SHOW_HIDDEN", "1");
    };
}

#[inline]
pub async fn run() -> color_eyre::Result<()> {
    color_eyre::install()?;
    // tracing::level_filters::LevelFilter::

    #[cfg(debug_assertions)]
    debugging_env!();
    // env::set_var("G_MESSAGES_DEBUG", "all");

    // #[cfg(debug_assertions)]
    // let filter = tracing::level_filters::LevelFilter::TRACE;

    // #[cfg(not(debug_assertions))]
    // let filter = CONFIG.verbose.log_level_filter();

    let current_sub = tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::DEFAULT_ENV)
        .with_max_level(CONFIG.verbose.log_level.tracing())
        .with_ansi(true)
        .with_file(true)
        .with_level(true)
        .with_line_number(true)
        .with_span_events(tracing_subscriber::fmt::format::FmtSpan::NEW)
        .with_target(true)
        .with_thread_ids(true)
        .with_writer(std::io::stdout)
        .finish();

    tracing_error::ErrorLayer::new(tracing_subscriber::fmt::format::Pretty::default())
        .with_subscriber(current_sub)
        .init();

    trace!("Config file contents:\n{}", &CONFIG.to_string());

    module_event_loop().await?;

    Ok(())
}

/// The backend event loop for all the modules. This will "block" the async task thread it is run on.
async fn module_event_loop() -> color_eyre::Result<()> {
    let (tx, mut rx) = mpsc::channel(128);
    let sender = Arc::new(tx);

    let modules = modules::Modules::new(Arc::clone(&sender)).await?;
    modules.run(Arc::clone(&sender)).await?;

    tokio::spawn(async move {
        while let Some(m) = rx.recv().await {
            debug!("{}", &m);
            // TODO: Do something with it
        }
    });

    bar::Bar::run()?;

    // config_new::ConfigNew::help()?;

    Ok(())
}

use crate::*;
use tracing_log::AsTrace;

#[inline]
pub async fn run() -> simple_eyre::Result<()> {
    simple_eyre::install()?;

    let args = config::Config::parse();

    #[cfg(debug_assertions)]
    env::set_var("G_MESSAGES_DEBUG", "all");
    #[cfg(debug_assertions)]
    let filter = clap_verbosity_flag::LevelFilter::Trace;

    #[cfg(not(debug_assertions))]
    let filter = args.verbose.log_level_filter();

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

    info!("Config file contents:\n{}", &args);

    module_event_loop(args).await?;

    Ok(())
}

/// The backend event loop for all the modules. This will "block" the async task thread it is run on.
#[tracing::instrument]
async fn module_event_loop(args: config::Config) -> simple_eyre::Result<()> {
    // let (tx, mut rx) = mpsc::channel(128);
    // let sender = Arc::new(tx);

    // let modules = modules::Modules::new(Arc::clone(&sender), args).await?;
    // modules.run(Arc::clone(&sender)).await?;

    // tokio::spawn(async move {
    //     while let Some(m) = rx.recv().await {
    //         println!("{}", &m);
    //         // TODO: Do something with it
    //     }
    // });

    bar::Bar::run()?;

    Ok(())
}

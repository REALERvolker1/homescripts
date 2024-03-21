use tracing::Level;
use tracing_subscriber::fmt::format::FmtSpan;

pub fn init() {
    tracing_subscriber::FmtSubscriber::builder()
        .compact()
        .with_max_level(LOG_LEVEL)
        .with_span_events(FmtSpan::EXIT)
        .with_writer(std::io::stderr)
        .with_level(true)
        .init();
}

#[cfg(not(debug_assertions))]
const LOG_LEVEL: Level = Level::INFO;

#[cfg(debug_assertions)]
const LOG_LEVEL: Level = Level::DEBUG;

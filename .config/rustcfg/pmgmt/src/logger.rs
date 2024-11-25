use {
    ::clap::Parser,
    ::core::str::FromStr,
    ::serde::{Deserialize, Serialize},
    ::std::{
        fs::File,
        io::IsTerminal,
        path::PathBuf,
        sync::{LazyLock, OnceLock},
    },
    ::tracing::{info, level_filters::LevelFilter},
    ::tracing_appender::non_blocking::WorkerGuard,
    ::tracing_subscriber::{
        fmt::{format::FmtSpan, FmtContext, MakeWriter},
        prelude::*,
        FmtSubscriber, Registry,
    },
};

/// so I am always using the correct stream
macro_rules! stdout {
    () => {
        stdout!(@fn)()
    };
    (@fn) => {
        ::std::io::stdout
    };
    (@type) => {
        ::std::io::Stdout
    };
}

#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    Serialize,
    Deserialize,
    clap::ValueEnum,
    strum_macros::Display,
    strum_macros::EnumString,
)]
#[serde(rename_all = "lowercase")]
#[strum(serialize_all = "lowercase")]
pub enum LogColor {
    /// Always show ANSI colors in logs
    Always,
    /// Only show ANSI colors if running in a terminal
    #[default]
    Auto,
    /// Never show ANSI colors
    Never,
}
impl LogColor {
    /// Automatically detect if stdout is a terminal. Used for the logging init.
    pub fn detect(self) -> bool {
        match self {
            Self::Always => true,
            Self::Auto => stdout!().is_terminal(),
            Self::Never => false,
        }
    }
}

/// The logging level. Determines what kind of log messages will be printed.
#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Serialize,
    Deserialize,
    strum_macros::Display,
    strum_macros::EnumString,
    clap::ValueEnum,
)]
#[serde(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum LogLevel {
    /// Disable all logging
    Disable,
    /// Only log errors
    Error,
    /// Log warnings as well as errors
    #[cfg_attr(not(debug_assertions), default)]
    Warn,
    /// Log other information that might be useful
    #[cfg_attr(debug_assertions, default)]
    // #[default]
    Info,
    /// Enable debug logging. This can be very verbose!
    Debug,
    /// Enable debug logging as well as trace logging. Even more verbose!
    Trace,
}

impl LogLevel {
    pub const fn tracing(&self) -> Option<tracing::Level> {
        let lvl = match self {
            Self::Disable => return None,
            Self::Error => tracing::Level::ERROR,
            Self::Warn => tracing::Level::WARN,
            Self::Info => tracing::Level::INFO,
            Self::Debug => tracing::Level::DEBUG,
            Self::Trace => tracing::Level::TRACE,
        };
        return Some(lvl);
    }
    pub const fn level_filter(&self) -> LevelFilter {
        match self {
            Self::Disable => LevelFilter::OFF,
            Self::Error => LevelFilter::ERROR,
            Self::Warn => LevelFilter::WARN,
            Self::Info => LevelFilter::INFO,
            Self::Debug => LevelFilter::DEBUG,
            Self::Trace => LevelFilter::TRACE,
        }
    }
    /// The filter to use for other crates that spew garbage, so they are nicer
    ///
    /// This is here so I can use level filter but keep these a bit less verbose.
    pub const fn nice_level_filter(&self) -> LevelFilter {
        match self {
            Self::Disable => LevelFilter::OFF,
            Self::Error => LevelFilter::ERROR,
            Self::Debug => LevelFilter::DEBUG,
            Self::Trace => LevelFilter::TRACE,
            _ => LevelFilter::WARN,
        }
    }
}

static LOG_GUARD: OnceLock<WorkerGuard> = OnceLock::new();

pub fn is_logger_init() -> bool {
    LOG_GUARD.get().is_some()
}

pub fn start_logger(
    color: LogColor,
    detailed: bool,
    level: LogLevel,
    logfile: Option<PathBuf>,
) -> Result<(), LogError> {
    let mut formatter = tracing_subscriber::fmt::format::Format::default().with_level(true);

    // tracing_subscriber::fmt::SubscriberBuilder::default().event_format(fmt_event)

    if detailed {
        formatter = formatter
            .with_target(true)
            .with_file(true)
            .with_line_number(true)
            .with_thread_ids(true)
            .with_thread_names(true);
    }

    let (writer, guard, formatter) = match logfile {
        Some(file) => {
            let fh = std::fs::File::create(file)?;
            let (writer, guard) = tracing_appender::non_blocking(fh);

            (writer, guard, formatter.with_ansi(false))
        }
        None => {
            let (writer, guard) = tracing_appender::non_blocking(stdout!());

            (writer, guard, formatter.with_ansi(color.detect()))
        }
    };

    LOG_GUARD.set(guard).expect("Could not set LOG_GUARD");

    let my_filter = level.level_filter();
    let nice_filter = level.nice_level_filter();

    let shut_up_zbus = tracing_subscriber::filter::Targets::new()
        .with_default(my_filter)
        .with_target("zbus", nice_filter)
        .with_target("zbus_xml", nice_filter);

    let subscriber = tracing_subscriber::fmt::fmt()
        .with_max_level(level.tracing())
        .event_format(formatter)
        .with_span_events(FmtSpan::ACTIVE)
        .with_writer(writer)
        .finish()
        .with(shut_up_zbus);

    // let filtered_subscriber = subscriber.with(shut_up_zbus);

    subscriber.init();

    Ok(())
}

#[derive(Debug, thiserror::Error)]
#[error("Failed to create logfile: {0}")]
pub struct LogError(#[from] std::io::Error);

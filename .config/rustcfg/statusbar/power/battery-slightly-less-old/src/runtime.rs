//! TODO: Add named pipe output
//! TODO: Add clap argparsing
//! TODO: Add logfile output
use crate::{modules::*, *};
use futures::StreamExt;
use tracing::{debug, info, warn};

#[inline]
pub async fn run_experimental() -> color_eyre::Result<()> {
    log_init();
    Ok(())
}

/// The main runtime entry point
///
/// It is single-threaded to use less system resources, as raw speed is not as important in this program.
#[inline]
pub async fn run() -> Result<(), types::ModError> {
    log_init();
    warn!("Starting up");

    let connection = zbus::ConnectionBuilder::system()?.build().await?;
    info!("Config loaded, connected to dbus");

    // load modules
    let (mut global_state, _proxies, listeners, sgfx_proxy) =
        modules::store::load_modules(&connection).await?;
    info!("Loaded modules");

    if listeners.len() == 0 {
        return Err(types::ModError::Other(
            "No modules to listen to!".to_owned(),
        ));
    }

    let mut futes = futures::stream::select_all(listeners);
    info!("Starting main loop");

    while let Some(v) = futes.next().await {
        if let Ok(state) = modules::StateType::from_weak(v).await {
            if state.is_super_gfx_power() {
                if let Some(p) = &sgfx_proxy {
                    global_state.update_sgfx_icon(p).await;
                }
            } else {
                // it should log a success internally
                global_state.update(state);
            }
            let state_string = global_state.string();
            // TODO: Use named pipes or a dbus propertychanged event
            println!("{}", state_string);

            debug!("{:?}", global_state);
        }
    }

    Ok(())
}

#[inline]
pub fn log_init() {
    eprintln!("Initializing logging");
    // let env_logging = EnvFilter::from_default_env();
    if cfg!(debug_assertions) {
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
    }
    info!("Logging initialized");
}

pub async fn test_supergfxd() -> zbus::Result<()> {
    log_init();
    let conn = zbus::Connection::system().await?;
    let proxy = modules::supergfxd::xmlgen::DaemonProxy::new(&conn).await?;

    let mut sig = proxy.receive_notify_gfx_status().await?;
    while let Some(s) = sig.next().await {
        println!("power {:?}", proxy.power().await?);
    }

    Ok(())
}

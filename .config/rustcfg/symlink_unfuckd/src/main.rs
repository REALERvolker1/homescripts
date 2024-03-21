pub mod config;
pub mod lockfile;
pub mod logging;

pub const BIN: &str = env!("CARGO_PKG_NAME");

#[cfg(target_os = "linux")]
fn main() -> std::io::Result<()> {
    logging::init();
    std::panic::set_hook(Box::new(|i| {
        tracing::error!("{i}");
        std::process::exit(3);
    }));

    lockfile::check_locked();

    let mut paths = config::get_filepaths()?;
    let mut buffer = [0u8; 4096];

    lockfile::lock()?;

    std::thread::spawn(signal_thread);

    let mut inotify = paths.init_inotify()?;

    loop {
        let events = inotify.read_events_blocking(&mut buffer)?;
        for _ in events {
            paths.rm_symlinks()
        }
    }
}

fn signal_thread() {
    let mut signals = signal_hook::iterator::Signals::new(&[
        signal_hook::consts::SIGINT,
        signal_hook::consts::SIGTERM,
        signal_hook::consts::SIGABRT,
    ])
    .unwrap();

    for sig in signals.forever() {
        panic!(
            "Received signal: {}",
            signal_hook::low_level::signal_name(sig).unwrap_or_default()
        );
    }
}

mod argparse;
mod daemon;
mod dbus_server;
mod logger;
mod rofi;
mod utils;
mod xmlgen;

pub type R<T> = Result<T, color_eyre::Report>;

fn main() -> R<()> {
    let args = argparse::Args::new()?;

    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_io()
        .build()
        .expect("Failed to initialize tokio runtime!");

    runtime.block_on(async move {});

    Ok(())
}

#[derive(Debug, thiserror::Error)]
pub enum CrateErrorKind {
    #[error("Failed to initialize: {0}")]
    Init(#[from] argparse::ArgParseError),
}

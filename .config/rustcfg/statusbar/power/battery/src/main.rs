#![forbid(unsafe_code)]

mod config;
// mod ipc;
mod modules;
mod runtime;
mod types;

/// The main function
///
/// Like any good asynchronous program, it basically implements a poorly written half of an OS scheduler.
// #[tokio::main(flavor = "current_thread")]
#[tokio::main]
async fn main() -> eyre::Result<()> {
    runtime::run().await?;
    Ok(())
}

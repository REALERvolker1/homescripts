#![forbid(unsafe_code)]
mod config;
mod modules;
mod runtime;
mod types;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), types::ModError> {
    runtime::run().await
}

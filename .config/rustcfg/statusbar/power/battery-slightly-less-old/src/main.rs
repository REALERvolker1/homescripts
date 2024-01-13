#![forbid(unsafe_code)]
// mod config;
mod cli;
mod experimental;
mod ipc;
mod modules;
mod runtime;
mod types;

#[tokio::main(flavor = "current_thread")]
async fn main() -> color_eyre::Result<()> {
    runtime::run_experimental().await?;
    // runtime::test_supergfxd().await.unwrap();
    Ok(())
}

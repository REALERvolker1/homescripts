#![forbid(unsafe_code)]

mod config;
// mod ipc;
mod modules;
mod runtime;
mod types;

#[tokio::main(flavor = "current_thread")]
async fn main() -> eyre::Result<()> {
    runtime::run().await?;
    // runtime::test_supergfxd().await.unwrap();
    Ok(())
}

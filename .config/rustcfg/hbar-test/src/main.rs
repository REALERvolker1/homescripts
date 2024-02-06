#![forbid(unsafe_code)]
pub use hbar::*;

// async fn initialize_modules() -> Bruh<Vec<RunReturn>> {}

#[tokio::main(flavor = "current_thread")]
async fn main() -> simple_eyre::Result<()> {
    simple_eyre::install()?;

    let (tx, rx) = tokio::sync::mpsc::channel::<MpscData>(16);
    runtime::run().await?;

    Ok(())
}

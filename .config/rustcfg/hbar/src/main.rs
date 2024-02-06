use hbar::*;
use tokio::runtime::Builder as Rt;

fn main() -> simple_eyre::Result<()> {
    simple_eyre::install()?;
    let current_runtime = Rt::new_multi_thread().enable_all().build()?;
    current_runtime.block_on(async move { run().await })?;
    Ok(())
}

/// The actual main function
async fn run() -> simple_eyre::Result<()> {
    // the main channel
    let (tx, mut rx) = mpsc::channel(128);
    let sender = Arc::new(tx);

    let modules = modules::Modules::new(Arc::clone(&sender)).await?;

    modules.run(Arc::clone(&sender)).await?;
    // println!("{:#?}", modules);

    while let Some(m) = rx.recv().await {
        println!("{:?}", m);
    }
    Ok(())
}

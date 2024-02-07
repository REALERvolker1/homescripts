use hbar::*;

#[tokio::main]
async fn main() -> simple_eyre::Result<()> {
    simple_eyre::install()?;
    println!("{}", config::Config::default().get_example_config().await?);
    // module_event_loop().await?;
    Ok(())
}

/// The backend event loop for all the modules. This will "block" the async task thread it is run on.
async fn module_event_loop() -> simple_eyre::Result<()> {
    let (tx, mut rx) = mpsc::channel(128);
    let sender = Arc::new(tx);

    let modules = modules::Modules::new(Arc::clone(&sender)).await?;

    // TODO: Validation and stuff, set up gtk settings, etc.

    modules.run(Arc::clone(&sender)).await?;

    while let Some(m) = rx.recv().await {
        println!("{:?}", m);
    }
    Ok(())
}

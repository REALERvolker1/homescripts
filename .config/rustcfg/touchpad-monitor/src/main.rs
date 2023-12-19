use clap::Parser;
use env_logger;
use eyre;
use log;
use std::env;

mod backends;
mod shared_udev;

#[derive(Parser, Debug)]
#[command(author = "vlk", version, about, long_about = None)]
struct Args {
    #[arg(short, long, required = true)]
    device: String,
    #[arg(short, long, required = false, default_value = "auto")]
    backend: backends::Backend,
    #[arg(short, long, required = false, default_value = "false")]
    verbose: bool,
}

#[tokio::main]
async fn main() -> eyre::Result<()> {
    let args = Args::parse();

    println!("Error! This project is unfinished!!!");
    return Ok(());

    if args.verbose {
        env::set_var("RUST_LOG", "debug");
        env_logger::init();
        log::info!("Enabling verbose logging");
    }

    let ensure_backend = backends::Backend::ensure(args.backend);
    let backend = if let Ok(b) = ensure_backend {
        b
    } else {
        let error = ensure_backend.unwrap_err();
        log::error!("Backend error: {}", error);
        return Err(eyre::eyre!(error));
    };

    shared_udev::monitor_devices().await?;

    println!("{:#?}\n\nBackend: {:?}", args, backend);
    Ok(())
}

/*

Outline:
Get device, make sure it exists on that backend, then watch for events pertaining to the device


*/

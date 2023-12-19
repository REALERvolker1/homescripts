use clap::{self, Parser};
use env_logger;
use eyre;
use hyprland::{self, shared::HyprData};
use log;
use std::{env, io};

#[derive(Debug, Clone, Copy)]
enum DeviceType {
    Keyboard,
    Mouse,
    Tablet,
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    device: String,
    #[arg(short, long)]
    device_type: DeviceType,
    #[arg(short, long)]
    verbose: bool,
}

fn main() -> eyre::Result<()> {
    let args = Args::parse();

    if args.verbose {
        env::set_var("RUST_LOG", "debug");
        env_logger::init();
    }
    log::info!("starting up in verbose mode");

    let event_watcher = hyprland::event_listener::EventListener::

    // if devices..len() == 0 {}
    println!("Hello, world! Args: {:#?}", args);

    Ok(())
}

#[macro_export]
macro_rules! device_name_vec {
    ($x:expr) => {
        $x.iter().map(|x| x.name).collect()
    };
}

/// Looks for the device in the entire list of devices
fn device_sanity_check(device: &str) -> hyprland::Result<bool> {
    log::info!("Getting hyprland devices");
    let devices = hyprland::data::Devices::get()?;
    let mut device_vec = Vec::new();

    let keyboards = devices
        .keyboards
        .iter()
        .filter(|i| i.name == device)
        .collect::<Vec<_>>();

    let mice = devices
        .mice
        .iter()
        .filter(|i| i.name == device)
        .collect::<Vec<_>>();

    let tablets = devices
        .tablets
        .iter()
        .filter(|i| i.name.is_some())
        .filter(|i| i.name.unwrap_or("".to_owned()) == device)
        .collect::<Vec<_>>();

    Ok(true)
}

// use comfy_table;
use rand::prelude::*;
use std::{env, error::Error, process};
use sysinfo::{Cpu, Disk, DiskUsage, System, SystemExt, User};

#[derive(Debug, Clone)]
struct Property {
    output_length: usize,
    output: String,
    color: u8,
    icon: String,
    label: String,
}

fn main() {
    let mut rng = rand::thread_rng();
    let box_color = rng.gen::<u8>();
    let mut sys = System::new_with_specifics(
        sysinfo::RefreshKind::with_disks(self)
    )

    println!("\x1b[38;5;{}mHello, world!\x1b[0m", box_color);
}

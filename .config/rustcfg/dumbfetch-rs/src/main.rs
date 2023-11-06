use chrono;
use std::{
    collections::HashMap,
    env::var,
    error::Error,
    fs, io,
    path::{Path, PathBuf},
    process, time,
};
use sysinfo::{DiskExt, RefreshKind, System, SystemExt};

fn main() -> Result<(), Box<dyn Error>> {
    let nvidia_version = process::Command::new("nvidia-settings")
        .arg("-v")
        .stdout(process::Stdio::piped())
        .output()?;
    let nvidia = String::from_utf8(nvidia_version.stdout)?;
    // cat /sys/module/nvidia/version

    let system = System::new_with_specifics(RefreshKind::new().with_disks_list());

    let mut entries: Vec<String> = Vec::new();

    // SHLVL
    entries.push(var("SHLVL").unwrap_or("999".to_string()));

    // UPTIME
    let uptime = system.uptime();
    let mut uptime_vec = Vec::new();

    let uptime_days = uptime / 86400;
    let uptime_hours = uptime / 3600;
    let uptime_mins = (uptime % 3600) / 60;
    // let uptime_secs = uptime % 60;

    match uptime_days {
        0 => {}
        1 => uptime_vec.push(format!("{} day", uptime_days)),
        _ => uptime_vec.push(format!("{} days", uptime_days)),
    };
    match uptime_days {
        0 => {}
        1 => uptime_vec.push(format!("{} hr", uptime_hours)),
        _ => uptime_vec.push(format!("{} hrs", uptime_hours)),
    };
    match uptime_mins {
        0 => {}
        1 => uptime_vec.push(format!("{} hr", uptime_mins)),
        _ => uptime_vec.push(format!("{} hrs", uptime_mins)),
    };

    entries.push(uptime_vec.join(", "));

    // TERM
    entries.push(var("TERM").unwrap_or("Undefined".to_string()));

    //DISKS
    // let mut done_disks = Vec::new();
    // for disk in system.disks() {
    //     let name = disk.name().to_str().unwrap();
    //     if ! {
    //         let percent = (100.0 - ((disk.available_space() as f64 / disk.total_space() as f64) * 100.0)) as i64;
    //         done_disks.push(name);
    //     }
    // }
    let mut disks = system
        .disks()
        .iter()
        .map(|i| {
            format!(
                "{}: {}",
                i.name().to_str().unwrap().replace("/dev/", ""),
                (100.0 - ((i.available_space() as f64 / i.total_space() as f64) * 100.0)).ceil()
                    as i64
            )
        })
        .collect::<Vec<String>>();
    disks.dedup();
    entries.push(disks.join("\n"));

    let kernel = system.kernel_version().unwrap_or_default();

    println!("{}", entries.join("\n"));
    // println!("{:?}", modules.get("nvidia_modeset").unwrap().state);

    Ok(())
}

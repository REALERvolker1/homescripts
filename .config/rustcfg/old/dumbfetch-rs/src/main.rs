use figlet_rs;
use rand::{self, Rng, SeedableRng};
use std::{
    collections::HashMap,
    env::{self, var},
    error::Error,
    fs, io,
    path::{Path, PathBuf},
    process, time,
};
use sysinfo::{DiskExt, RefreshKind, System, SystemExt};

#[derive(Debug, Clone)]
struct Entry {
    content: String,
    color: u8,
    key: String,
}

fn main() -> Result<(), Box<dyn Error>> {
    let has_full_color = var("COLORTERM").unwrap_or("".to_string()) == "truecolor";
    // let mut rng = rand::thread_rng();
    let color_prefix = if has_full_color { "8;5;" } else { "" };

    let mut entries: Vec<Entry> = Vec::new();

    let system = System::new_with_specifics(RefreshKind::new().with_disks_list());

    // SHLVL
    let shlvl_content = var("SHLVL").unwrap_or("N/A".to_string());
    entries.push(Entry {
        content: shlvl_content.clone(),
        color: if has_full_color { 21 } else { 4 },
        key: " SHLVL ".to_string(),
    });

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
    match uptime_hours {
        0 => {}
        1 => uptime_vec.push(format!("{} hr", uptime_hours)),
        _ => uptime_vec.push(format!("{} hrs", uptime_hours)),
    };
    match uptime_mins {
        0 => {}
        1 => uptime_vec.push(format!("{} min", uptime_mins)),
        _ => uptime_vec.push(format!("{} mins", uptime_mins)),
    };
    let uptime_str = uptime_vec.join(", ");

    entries.push(Entry {
        content: uptime_str.clone(),
        color: if has_full_color { 129 } else { 5 },
        key: "󰅐 Uptime".to_string(),
    });

    // TERM
    let term_content = var("TERM").unwrap_or("N/A".to_string());
    entries.push(Entry {
        content: term_content.clone(),
        color: if has_full_color { 45 } else { 6 },
        key: " Term  ".to_string(),
    });

    // disks
    let disk_color: u8 = if has_full_color { 226 } else { 3 };
    let mut disks = system
        .disks()
        .iter()
        .filter_map(|i| {
            if let Ok(fstype) = String::from_utf8(i.file_system().to_vec()) {
                return match fstype.as_str() {
                    "btrfs" | "xfs" | "ext4" => Some(format!(
                        "{}%",
                        (100.0 - ((i.available_space() as f64 / i.total_space() as f64) * 100.0))
                            .ceil() as i64
                    )),

                    _ => None,
                };
            } else {
                return None;
            }
        })
        .collect::<Vec<String>>();
    disks.dedup();
    let disk_string = disks.join(", ");

    entries.push(Entry {
        content: disk_string.clone(),
        color: disk_color,
        key: "󰋊 Disk  ".to_string(),
    });

    // nvidia drivers (or distrobox) version
    let (version_str, version_header) = if let Ok(distrobox_version) = var("CONTAINER_ID") {
        (distrobox_version, "󰏖 Distbx")
    } else {
        (
            fs::read_to_string("/sys/module/nvidia/version")
                .unwrap_or("Non-Proprietary".to_string())
                .trim()
                .to_string(),
            "󰾲 Nvidia",
        )
    };
    entries.push(Entry {
        content: version_str.clone(),
        color: if has_full_color { 46 } else { 2 },
        key: version_header.to_string(),
    });

    // kernel version
    let kernel = system
        .kernel_version()
        .unwrap_or_default()
        .split("-")
        .take(2)
        .collect::<Vec<&str>>()
        .join("-");

    entries.push(Entry {
        content: kernel.clone(),
        color: if has_full_color { 196 } else { 1 },
        key: " Kernel".to_string(),
    });

    let user = var("USER").unwrap_or("".to_string());

    let mut figletvec = Vec::new();
    if user.len() < 6 && !user.is_empty() {
        if let Ok(stdfigfont) = figlet_rs::FIGfont::standard() {
            if let Some(figure) = stdfigfont.convert(&user) {
                let figurestr = figure.to_string();
                let mut fig = figurestr.lines().collect::<Vec<&str>>();
                figletvec.append(&mut fig);
            }
        }
    };
    if figletvec.is_empty() {
        figletvec = vec![
            "     _  __ _       _     ",
            "  __| |/ _| |_ ___| |__  ",
            " / _` | |_| __/ __| '_ \\ ",
            "| (_| |  _| || (__| | | |",
            " \\__,_|_|  \\__\\___|_| |_|",
            "                         ",
        ];
    }
    let mut figlet = figletvec.iter();
    let figcount = figletvec
        .iter()
        .map(|i| i.chars().count())
        .max()
        .unwrap_or(0);

    let figpad = " ".repeat(figcount);

    // let figlet_arr = [
    //     "     _  __ _       _     ",
    //     "  __| |/ _| |_ ___| |__  ",
    //     " / _` | |_| __/ __| '_ \\ ",
    //     "| (_| |  _| || (__| | | |",
    //     " \\__,_|_|  \\__\\___|_| |_|",
    //     figlet_empty,
    // ];
    // let mut figlet = figlet_arr.iter();

    let mut rng = rand::rngs::SmallRng::seed_from_u64(uptime);
    let (box_color, figlet_color) = if has_full_color {
        (rng.gen::<u8>(), rng.gen::<u8>())
    } else {
        (rng.gen::<u8>() % 7, rng.gen::<u8>() % 7)
    };
    let box_side = format!("\x1b[0;3{}{}m│\x1b[0m", color_prefix, box_color);

    let entry_length = entries
        .iter()
        .map(|i| i.content.chars().count())
        .max()
        .unwrap_or(0);

    let mut ind = 0;
    for i in entries.iter() {
        println!(
            "{}\x1b[3{}{}m {} {}\x1b[3{}{}m {}  \x1b[1m{:entry_length$} {}",
            &box_side,
            color_prefix,
            figlet_color,
            figlet.next().unwrap_or(&figpad.as_str()),
            &box_side,
            color_prefix,
            i.color,
            i.key,
            i.content,
            &box_side
        );
        ind += 1;
    }
    // "\x1b[{}{}m", color_prefix, color_int
    Ok(())
}

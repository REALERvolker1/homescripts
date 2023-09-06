use std::{
    io,
    fs,
    env,
    path::Path,
    process,
};
use inotify::{
    Inotify,
    WatchMask,
};

fn main() -> Result<(), io::Error> {
    let comm = process::Command::new("pointer.sh")
        .arg("-p")
        .output()?;
    let command_string = String::from_utf8(comm.stdout).unwrap();
    let filepath = Path::new(command_string.trim());
    if ! filepath.exists() {
        println!("Err");
    }
    let mut inotify = Inotify::init()?;
    inotify.watches().add(filepath, WatchMask::MODIFY)?;
    let mut buffer = [0; 1024];
    loop {
        println!("{}", match fs::read_to_string(filepath)?.as_str() {
            "1" => "󰟸",
            "0" => "󰤳",
            _ => "󰟸 ?"
        });
        inotify.read_events_blocking(&mut buffer)?;
    }
    Ok(())
}

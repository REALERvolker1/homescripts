use std::{env, process};

/// Returns true if the current user has their sudo password cached.
pub fn has_sudo() -> bool {
    if let Ok(su) = process::Command::new("sudo")
        .arg("-vn")
        .stderr(process::Stdio::null())
        .stdout(process::Stdio::null())
        .status()
    {
        su.success()
    } else {
        false
    }
}

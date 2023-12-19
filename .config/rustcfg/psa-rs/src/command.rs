use std::{io, process};

macro_rules! termsize_err {
    () => {
        Err(io::Error::new(
            io::ErrorKind::Other,
            "failed to get terminal size",
        ))
    };
}

pub fn terminal_width() -> io::Result<usize> {
    let size_cmd_output = process::Command::new("tput").arg("cols").output();

    if let Ok(size_cmd) = size_cmd_output {
        let stdout = String::from_utf8_lossy(&size_cmd.stdout);
        println!("{}", &stdout);
        if let Ok(cols) = stdout.trim().parse::<usize>() {
            Ok(cols)
        } else {
            termsize_err!()
        }
    } else {
        Err(size_cmd_output.unwrap_err())
    }
}

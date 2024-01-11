use std::{env, process};

/// It's really not pretty but idk how to do build.rs
fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    let cwd = env::current_dir().expect("Failed to get current working directory");
    let generate_script = cwd.join("generate.sh");

    let script = process::Command::new(&generate_script)
        .output()
        .expect("Failed to run XML generate script");

    if !script.status.success() {
        println!(
            "Generate script failed with exit code {:?}\nStdout: {}\nStderr: {}",
            script.status.code(),
            String::from_utf8_lossy(&script.stdout),
            String::from_utf8_lossy(&script.stderr)
        );
    }
}

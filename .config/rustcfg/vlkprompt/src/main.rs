// use std::{env, io};

mod config;
mod configlib;
mod format;
mod prompt;

fn main() {
    init()
}

fn init() {
    let hostname = prompt::hostname::Hostname::new();
    println!("hostname: {:?}!", hostname);
}

use serde::{Deserialize, Serialize};
use std::{env, process};

#[derive(Debug, Clone, Default, Copy, Serialize, Deserialize)]
pub enum OutputType {
    Waybar,
    #[default]
    Stdout,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Config {
    pub output_type: OutputType,
}

impl Config {
    pub fn from_args() -> Option<Self> {
        let mut output_type = OutputType::default();
        let mut print_help_arg = "".to_string();
        for i in env::args().skip(1) {
            match i.as_str() {
                "--waybar" => output_type = OutputType::Waybar,
                "--stdout" => output_type = OutputType::Stdout,
                _ => print_help_arg = i.clone(),
            }
        }
        if print_help_arg.is_empty() {
            Some(Self { output_type })
        } else {
            println!("Error, invalid arg detected! '{}'\n--waybar\tOutput waybar-formatted text\n--stdout\tPrint text formatted for stdout (default)", &print_help_arg);
            process::exit(1)
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            output_type: OutputType::default(),
        }
    }
}

//! The module that gets the config
use crate::modules::upower::Percent;

/// What kind of output is requested
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub enum OutputType {
    #[default]
    Stdout,
    Waybar,
    // TODO: Add more output types
}


/// The main config
#[derive(Debug, Clone)]
pub struct Config {
    pub display_type: OutputType,
    pub charge_end_threshold: Percent,
    pub ac_high_draw_threshold: f64,
    pub bat_high_draw_threshold: f64,
    pub low_power: Percent,
}
impl Default for Config {
    fn default() -> Self {
        Config {
            display_type: OutputType::default(),
            charge_end_threshold: Percent::max(),
            ac_high_draw_threshold: 70.0,
            bat_high_draw_threshold: 20.0,
            low_power: Percent::from_u8_unchecked(10),
        }
    }
}

/// The function to get the config (configurable), does argparsing too
pub async fn get_config() -> Config {
    let mut config = Config::default();

    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--waybar" => config.display_type = OutputType::Waybar,
            "--stdout" => config.display_type = OutputType::Stdout,
            "--charge-end-threshold" => {
                if let Some(cc) = args.next() {
                    // if let Ok(c) = cc.trim().parse::<u8>() {
                    //     if c <= 100 {
                    //         config.charge_end_threshold = c;
                    //     } else {
                    //         print_help(
                    //             &c.to_string(),
                    //             Some("Invalid percentage for --charge-end-threshold"),
                    //         );
                    //     }
                    // } else {
                    //     print_help(&cc, Some("Invalid percentage for --charge-end-threshold"));
                    // }
                    config.charge_end_threshold = Percent::try_from_str(&cc).unwrap();
                } else {
                    print_help(
                        "<int 0-100>",
                        Some("Missing percentage for --charge-end-threshold"),
                    );
                }
            }
            _ => print_help(&arg, None),
        }
    }
    // if config.charge_end_threshold == u8::MAX {
    //     config.charge_end_threshold =
    //         if let Ok(c) = tokio::fs::read_to_string("/sys/class/power_supply/BAT1/charge_control_end_threshold").await {
    //             if let Ok(e) = c.trim().parse::<upower::Percent>() {
    //                 e
    //             } else {
    //                 100
    //             }
    //         } else {
    //             100
    //         };
    // }
    config
}

pub fn print_help(invalid_arg: &str, reason: Option<&str>) {
    eprintln!(
        "\x1b[0;1mUsage\x1b[0m

--waybar     format output for waybar
--stdout     format output for stdout

\x1b[1mModule options\x1b[0m

--charge-end-threshold <int 0-100>     Set the max battery charge percentage
"
    );
    panic!("{}: {}", reason.unwrap_or("Invalid argument"), invalid_arg);
}

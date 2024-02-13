use chrono::Local;

use super::*;

config_struct! {
    TimeConfig, TimeConfigOptions,

    default: "%a %m/%d/%Y".to_owned(),
    help: "Format for the date string",
    long_help: "Format for the date string. See `man strftime` for more info.",
    date_format: String,

    default: "%I:%M:%S %p".to_owned(),
    help: "Format for the time string",
    long_help: "Format for the time string. See `man strftime` for more info.",
    time_format: String,

    default: 750,
    help: "The polling rate in milliseconds",
    long_help: "The polling rate in milliseconds. Avoid setting this manually, unless you're really hurting for performance. Set this under 1000 if you don't want to skip seconds.",
    time_poll_rate_ms: u64,
}

#[derive(Debug, Clone, Copy)]
pub struct TimeModule {
    poll_rate: Duration,
}
// I want to use async module so I don't have to wait for the sender to send
impl Module for TimeModule {
    type StartupData = ();
    #[tracing::instrument(skip_all, level = "debug")]
    async fn new(_: Self::StartupData) -> ModResult<(Self, modules::ModuleData)> {
        let me = Self {
            poll_rate: Duration::from_millis(CONFIG.time.time_poll_rate_ms),
        };

        let time = Self::get().into();
        Ok((me, time))
    }
    #[tracing::instrument(skip_all, level = "debug")]
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        loop {
            let send_res = join!(sender.send(Self::get().into()), sleep!(self.poll_rate));
            send_res.0?;
        }
    }
}
impl TimeModule {
    pub fn get() -> DateTimeData {
        let time = Local::now();
        DateTimeData {
            date: time.format(&CONFIG.time.date_format).to_string(),
            time: time.format(&CONFIG.time.time_format).to_string(),
        }
    }
}

#[derive(Debug, Default, Clone, Serialize, Deserialize, derive_more::Display)]
#[display(fmt = "{} @ {}", date, time)]
pub struct DateTimeData {
    pub date: String,
    pub time: String,
}

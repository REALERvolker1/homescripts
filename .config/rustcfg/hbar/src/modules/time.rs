use chrono::Local;

use crate::*;

const DEFAULT_DATE_FORMAT: &str = "%a %m/%d/%Y";
const DEFAULT_TIME_FORMAT: &str = "%I:%M:%S %p";
const DEFAULT_TIME_POLL_RATE_MS: u64 = 500;

/// The configuration for the datetime module.
#[derive(Debug, Clone, Parser, Serialize, Deserialize, SmartDefault)]
pub struct Time {
    #[arg(
        long,
        default_value = DEFAULT_DATE_FORMAT,
        help = "Format for the date string",
        long_help = "Format for the date string. See `man strftime` for more info."
    )]
    #[default(DEFAULT_DATE_FORMAT.into())]
    pub date_format: String,

    #[arg(
        long,
        default_value = DEFAULT_TIME_FORMAT,
        help = "Format for the time string",
        long_help = "Format for the time string. See `man strftime` for more info."
    )]
    #[default(DEFAULT_TIME_FORMAT.into())]
    pub time_format: String,

    #[arg(
        long = "time-poll-rate-ms",
        default_value_t = DEFAULT_TIME_POLL_RATE_MS,
        help = "The polling rate in milliseconds",
        long_help = "The polling rate in milliseconds. Avoid setting this manually, unless you're really hurting for performance. Set this under 1000 if you don't want to skip seconds."
    )]
    #[default(DEFAULT_TIME_POLL_RATE_MS)]
    pub poll_rate_ms: u64,

    /// Durations are ugly when serialized. I keep this private and skip it.
    #[serde(skip)]
    #[arg(skip)]
    polling_rate_internal: Duration,
}
// I want to use async module so I don't have to wait for the sender to send
impl Module for Time {
    type StartupData = Self;
    #[tracing::instrument(skip(data))]
    async fn new(data: Self::StartupData) -> ModResult<(Self, modules::ModuleData)> {
        let mut me = data;
        me.polling_rate_internal = Duration::from_millis(me.poll_rate_ms);
        let time = me.get().into();
        Ok((me, time))
    }
    #[tracing::instrument(skip(self, sender))]
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        loop {
            let send_res = join!(
                sender.send(self.get().into()),
                sleep!(self.polling_rate_internal)
            );
            send_res.0?;
        }
    }
}
impl Time {
    pub fn get(&self) -> DateTimeData {
        let time = Local::now();
        DateTimeData {
            date: time.format(&self.date_format).to_string(),
            time: time.format(&self.time_format).to_string(),
        }
    }
}

#[derive(Debug, Default, Clone, Serialize, Deserialize, derive_more::Display)]
#[display(fmt = "{} @ {}", date, time)]
pub struct DateTimeData {
    pub date: String,
    pub time: String,
}

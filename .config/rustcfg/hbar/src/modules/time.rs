use chrono::Local;

use crate::*;

/// The configuration for the datetime module.
#[derive(Debug, Clone, Serialize, Deserialize, SmartDefault)]
pub struct Time {
    /// The format to use for the date. See `man strftime` for more info.
    #[default = "%a %m/%d/%Y"]
    pub date_format: String,
    /// The format to use for the time.
    #[default = "%I:%M:%S %p"]
    pub time_format: String,

    /// The polling rate in milliseconds. Avoid setting this manually,
    /// unless you're really hurting for performance.
    ///
    /// Set this under 1000 if you want to see seconds.
    #[default(Duration::from_millis(1000))]
    pub poll_rate: Duration,
}
// I want to use async module so I don't have to wait for the sender to send
impl Module for Time {
    type StartupData = Self;
    async fn new(data: Self::StartupData) -> ModResult<(Self, modules::ModuleData)> {
        let time = data.get().into();
        Ok((data, time))
    }
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        loop {
            let send_res = join!(sender.send(self.get().into()), sleep!(self.poll_rate));
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

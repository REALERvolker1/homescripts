//! This module polls [wttr.in](wttr.in) for weather data.
use super::{ModuleData, ModuleSender};
use crate::*;
/// The Weather module. It is advised not to change a bunch of settings in here.
#[derive(Debug, Clone, Serialize, Deserialize, SmartDefault)]
pub struct Weather {
    /// The weather URL. It is advised not to change it. The raw text grabbed from this endpoint is just displayed.
    #[default = "v2n.wttr.in?format=%c%t"]
    pub weather_url: String,
    /// The polling rate, in seconds.
    #[default = 300]
    pub poll_rate: u64,
    /// Durations are ugly when serialized. I keep this private and skip it.
    #[serde(skip)]
    polling_rate_internal: Duration,
}
impl Module for Weather {
    type StartupData = Self;
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        let mut me = data;
        me.polling_rate_internal = Duration::from_secs(me.poll_rate);
        Ok((me, ModuleData::Weather(String::from("⛅"))))
    }
    async fn run(&mut self, sender: ModuleSender) -> ModResult<()> {
        loop {
            let resp = reqwest::get(&self.weather_url).await?;
            // resp.status().canonical_reason()
            let text = match resp.text().await {
                Ok(text) => text,
                Err(e) => {
                    return Err(e.into());
                }
            };
            let send_res = join!(
                sender.send(ModuleData::Weather(text)),
                sleep!(self.polling_rate_internal)
            );
            send_res.0?;
        }
    }
}

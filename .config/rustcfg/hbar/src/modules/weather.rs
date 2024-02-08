//! This module polls [wttr.in](wttr.in) for weather data.
use super::{ModuleData, ModuleSender};
use crate::*;

const DEFAULT_WEATHER_URL: &str = "v2n.wttr.in?format=%c%t";
const DEFAULT_WEATHER_TIMEOUT: u64 = 300;

#[derive(Debug, Parser, Clone, Serialize, Deserialize, SmartDefault)]
pub struct Weather {
    #[default(DEFAULT_WEATHER_URL.into())]
    #[arg(
        long,
        default_value = DEFAULT_WEATHER_URL,
        help = "The URL endpoint for wttr.in",
        long_help = "The weather URL endpoint for wttr.in. It is advised not to change it. The raw text grabbed from this endpoint is just displayed."
    )]
    pub weather_url: String,
    #[default(DEFAULT_WEATHER_TIMEOUT)]
    #[arg(
        long = "weather-poll-rate",
        default_value_t = DEFAULT_WEATHER_TIMEOUT,
        help = "The weather poll rate, in seconds"
    )]
    pub poll_rate: u64,
    /// Durations are ugly when serialized. I keep this private and skip it.
    #[serde(skip)]
    #[arg(skip)]
    polling_rate_internal: Duration,
}
impl Module for Weather {
    type StartupData = Self;
    #[tracing::instrument(skip(data))]
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        let mut me = data;
        me.polling_rate_internal = Duration::from_secs(me.poll_rate);
        Ok((me, ModuleData::Weather(String::from("⛅"))))
    }
    #[tracing::instrument(skip(self, sender))]
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

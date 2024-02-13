//! This module polls [wttr.in](wttr.in) for weather data.
use super::*;

config_struct! {
    WeatherConfig, WeatherConfigOptions,

    default: "http://v2d.wttr.in".to_string(),
    help: "The URL endpoint for wttr.in",
    long_help: "The weather URL endpoint for wttr.in. It is advised not to change it. The raw text grabbed from this endpoint is just displayed.",
    weather_url: String,

    default: "%c%t".to_string(),
    help: "The weather output format",
    long_help: "The output format for weather. Please refer to https://github.com/chubin/wttr.in?tab=readme-ov-file#one-line-output as a guide.",
    wttr_format: String,

    default: 300,
    help: "The weather poll rate, in seconds",
    long_help: "The weather poll rate, in seconds",
    weather_poll_rate: u64,
}

const WEATHER_STR: &str = "⛅";

/// TODO: Remove this module
#[derive(Debug)]
pub struct WeatherModule {
    poll_rate: Duration,
    full_url: String,
    http_client: Arc<reqwest::Client>,
}
impl Module for WeatherModule {
    type StartupData = Arc<reqwest::Client>;
    #[tracing::instrument(skip_all, level = "debug")]
    async fn new(client: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        let me = Self {
            poll_rate: Duration::from_secs(CONFIG.weather.weather_poll_rate),
            full_url: format!(
                "{}?format=\"{}\"",
                CONFIG.weather.weather_url, CONFIG.weather.wttr_format
            ),
            http_client: client,
        };
        Ok((me, ModuleData::Weather(String::from(WEATHER_STR))))
    }
    #[tracing::instrument(skip_all, level = "debug")]
    async fn run(&mut self, sender: ModuleSender) -> ModResult<()> {
        loop {
            match self.get().await {
                Ok(t) => {
                    sender.send(ModuleData::Weather(t)).await?;
                }
                Err(e) => {
                    debug!("{}", e);
                }
            }
            sleep!(self.poll_rate).await;
        }
    }
}
impl WeatherModule {
    #[tracing::instrument(skip_all, level = "debug")]
    pub async fn get(&self) -> ModResult<String> {
        let res = self
            .http_client
            .get(&self.full_url)
            .send()
            .await?
            .text()
            .await?;

        Ok(res)
        // reqwest::get(&CONFIG.weather.weather_url)
        //     .await?
        //     .text()
        //     .await
        //     .map_err(Into::into)
    }
}

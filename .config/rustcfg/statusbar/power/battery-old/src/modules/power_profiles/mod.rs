use crate::modules;
use futures::{self, StreamExt};
use std::{fmt, str::FromStr};
use strum_macros::{Display, EnumString};
use tokio;
use zbus;

mod xmlgen;

pub struct PowerProfile<'a> {
    proxy: xmlgen::PowerProfilesProxy<'a>,
    state_stream: zbus::PropertyStream<'a, String>,
    pub state: PowerProfileType,
}
impl<'a> modules::ModuleExt<'a> for PowerProfile<'a> {
    fn get_state_string(&self, output_type: modules::OutputType) -> String {
        self.state.to_string()
    }
    async fn refresh_state(&mut self) -> zbus::Result<()> {
        let profile = self.proxy.active_profile().await?;
        self.state = PowerProfileType::from_str(&profile);
        Ok(())
    }
    async fn new(connection: &zbus::Connection) -> zbus::Result<modules::Property<'a>> {
        let proxy = xmlgen::PowerProfilesProxy::new(connection).await?;
        let current_state_raw = proxy.active_profile().await?;
        let state_stream = proxy.receive_active_profile_changed().await;

        let state = PowerProfileType::from_str(&current_state_raw);

        Ok(modules::Property::PowerProfile(Some(Self {
            proxy,
            state,
            state_stream,
        })))
    }
    fn proptype(&self) -> modules::Property<'a> {
        modules::Property::Battery(None)
    }
}
impl<'a> modules::Module<'a> for PowerProfile<'a> {
    async fn handle_event(
        &mut self,
        listener_type: modules::PropertyListener<'_>,
    ) -> zbus::Result<Option<()>> {
        if let modules::PropertyListener::PowerProfile(p) = listener_type {
            self.state = PowerProfileType::from_str(p.get().await?.as_str());
            return Ok(Some(()));
        }
        Ok(None)
    }
    async fn handle_next(&mut self) -> zbus::Result<()> {
        while let Some(v) = self.next().await {
            self.handle_event(v).await?;
        }
        Ok(())
    }
}
impl<'a> futures::Stream for PowerProfile<'a> {
    type Item = modules::PropertyListener<'a>;
    fn poll_next(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        if let std::task::Poll::Ready(v) = self.state_stream.poll_next_unpin(cx) {
            if let Some(p) = v {
                return std::task::Poll::Ready(Some(modules::PropertyListener::PowerProfile(p)));
            }
        }
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
}

#[derive(Debug, Default, Display, PartialEq, Eq, Copy, Clone)]
pub enum PowerProfileType {
    PowerSaver,
    Balanced,
    Performance,
    #[default]
    Unknown,
}
impl PowerProfileType {
    pub fn icon(&self) -> modules::Icon {
        match self {
            Self::PowerSaver => "󰌪",
            Self::Balanced => "󰛲",
            Self::Performance => "󱐋",
            _ => "󱐋?",
        }
    }
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().trim() {
            "power-saver" => Self::PowerSaver,
            "balanced" => Self::Balanced,
            "performance" => Self::Performance,
            _ => Self::Unknown,
        }
    }
}

use crate::modules;
use futures::StreamExt;
mod xmlgen;

pub struct PowerProfileProxy<'a> {
    pub proxy: xmlgen::PowerProfilesProxy<'a>,
    pub state_stream: zbus::PropertyStream<'a, String>,
}
impl<'a> modules::Proxy<'a> for PowerProfileProxy<'a> {
    async fn new(
        connection: &'a zbus::Connection,
    ) -> Option<(crate::modules::PropertyProxy, crate::modules::Property)> {
        let proxy = if let Ok(p) = xmlgen::PowerProfilesProxy::new(connection).await {
            p
        } else {
            return None;
        };

        let (state_raw, state_stream) = tokio::join!(
            proxy.active_profile(),
            proxy.receive_active_profile_changed()
        );

        let state = if let Ok(s) = state_raw {
            modules::Property::PowerProfile(PowerProfileState::from_string(s))
        } else {
            return None;
        };

        Some((
            modules::PropertyProxy::PowerProfile(Self {
                proxy,
                state_stream,
            }),
            state,
        ))
    }
    fn name() -> String {
        String::from("power_profiles")
    }
}

impl<'a> futures::Stream for PowerProfileProxy<'a> {
    type Item = modules::WeakStateType<'a>;
    fn poll_next(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        if let std::task::Poll::Ready(Some(s)) = self.state_stream.poll_next_unpin(cx) {
            return std::task::Poll::Ready(Some(modules::WeakStateType::PowerProfile(s)));
        }
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
}

#[derive(Debug, Default, strum_macros::Display, PartialEq, Eq, Copy, Clone)]
pub enum PowerProfileState {
    PowerSaver,
    Balanced,
    Performance,
    #[default]
    Unknown,
}
impl PowerProfileState {
    /// Get the status
    pub fn status_string<'a>(&self) -> &'a str {
        self.icon()
    }
    #[inline]
    pub fn icon(&self) -> modules::Icon {
        match self {
            Self::PowerSaver => "󰌪",
            Self::Balanced => "󰛲",
            Self::Performance => "󱐋",
            _ => "󱐋?",
        }
    }
    #[inline]
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().trim() {
            "power-saver" => Self::PowerSaver,
            "balanced" => Self::Balanced,
            "performance" => Self::Performance,
            _ => Self::Unknown,
        }
    }
    /// convenience function to wrap from_str
    #[inline]
    pub fn from_string(s: String) -> Self {
        Self::from_str(&s)
    }
}

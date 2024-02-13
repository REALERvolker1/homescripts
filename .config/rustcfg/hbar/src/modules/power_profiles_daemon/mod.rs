mod xmlgen;
use super::*;

#[derive(Debug)]
pub struct PowerProfiles<'a> {
    proxy: xmlgen::PowerProfilesProxy<'a>,
    listener: PropertyStream<'a, PowerProfileState>,
}
impl Module for PowerProfiles<'_> {
    type StartupData = Arc<Connection>;
    #[tracing::instrument(skip_all, level = "debug")]
    async fn new(data: Self::StartupData) -> ModResult<(Self, modules::ModuleData)> {
        let proxy = xmlgen::PowerProfilesProxy::new(&data).await?;
        let (prof, listener) = join!(
            proxy.active_profile(),
            proxy.receive_active_profile_changed()
        );
        Ok((Self { proxy, listener }, prof?.into()))
    }
    #[tracing::instrument(skip_all, level = "debug")]
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        while let Some(p) = self.listener.next().await {
            sender.send(p.get().await?.into()).await?;
        }
        Ok(())
    }
}
impl PowerProfiles<'_> {
    #[tracing::instrument(skip_all, level = "debug")]
    pub async fn active_profile(&self) -> ModResult<PowerProfileState> {
        Ok(self.proxy.active_profile().await?)
    }
}

#[derive(Debug, Default, Copy, Clone, strum_macros::Display, Serialize, Deserialize)]
#[strum(serialize_all = "kebab-case")]
pub enum PowerProfileState {
    PowerSaver,
    Balanced,
    Performance,
    #[default]
    Unknown,
}
impl From<&str> for PowerProfileState {
    fn from(value: &str) -> Self {
        match value {
            "power-saver" => Self::PowerSaver,
            "balanced" => Self::Balanced,
            "performance" => Self::Performance,
            _ => Self::default(),
        }
    }
}
impl TryFrom<zvariant::OwnedValue> for PowerProfileState {
    type Error = ModError;
    fn try_from(value: zvariant::OwnedValue) -> Result<Self, Self::Error> {
        Ok(if let Some(v) = value.downcast_ref() {
            Self::from(v)
        } else {
            Self::default()
        })
    }
}
impl PowerProfileState {
    pub fn icon(&self) -> Option<Icon> {
        match self {
            Self::PowerSaver => Some('󰌪'),
            Self::Balanced => Some('󰛲'),
            Self::Performance => Some('󱐋'),
            _ => None,
        }
    }
}

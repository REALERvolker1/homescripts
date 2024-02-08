mod xmlgen;
use crate::*;

// https://gitlab.com/asus-linux/supergfxctl

/// Several things about this module are different from normal propertylisteners,
/// because supergfxd does not publish changes in the same way as every single other program.
#[derive(Debug)]
pub struct GfxModule<'a> {
    proxy: xmlgen::DaemonProxy<'a>,
    current_state: GfxState,
    power_listener: xmlgen::NotifyGfxStatusStream<'a>,
    mode_listener: xmlgen::NotifyGfxStream<'a>,
}
impl<'a> Module for GfxModule<'a> {
    type StartupData = Arc<Connection>;
    #[tracing::instrument(skip(data))]
    async fn new(data: Self::StartupData) -> ModResult<(Self, modules::ModuleData)> {
        let proxy = xmlgen::DaemonProxy::new(&data).await?;

        let (mode, power, power_listener, mode_listener) = try_join!(
            proxy.mode(),
            proxy.power(),
            proxy.receive_notify_gfx_status(),
            proxy.receive_notify_gfx()
        )?;

        let current_state = GfxState { mode, power };
        Ok((
            Self {
                proxy,
                current_state,
                power_listener,
                mode_listener,
            },
            current_state.into(),
        ))
    }
    #[tracing::instrument(skip(self, sender))]
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        sender.send(self.current_state.into()).await?;
        loop {
            tokio::select! {
                Some(_) = self.power_listener.next() => {
                    let power = self.proxy.power().await?;
                    self.current_state.set_power(power);
                    sender.send(self.current_state.into()).await?;
                }
                Some(_) = self.mode_listener.next() => {
                    let mode = self.proxy.mode().await?;
                    self.current_state.set_mode(mode);
                    sender.send(self.current_state.into()).await?;
                }
            }
        }
    }
}

#[derive(Debug, Default, Copy, Clone, Serialize, Deserialize, derive_more::Display)]
#[display(fmt = "{}", "self.icon()")]
pub struct GfxState {
    pub mode: GfxMode,
    pub power: GfxPower,
}
impl GfxState {
    const fn icon(&self) -> Icon {
        match self.mode {
            GfxMode::Hybrid => match self.power {
                GfxPower::Active => '󰒇',
                GfxPower::Suspended => '󰒆',
                GfxPower::Off => '󰒅',
                GfxPower::AsusDisabled => '󰒈',
                GfxPower::AsusMuxDiscreet => '󰾂',
                GfxPower::Unknown => '󰳤',
            },
            GfxMode::Integrated => '󰰃',
            GfxMode::NvidiaNoModeset => '󰰒',
            GfxMode::Vfio => '󰰪',
            GfxMode::AsusEgpu => '󰯷',
            GfxMode::AsusMuxDgpu => '󰰏',
            GfxMode::None => '󰳤',
        }
    }
    pub fn set_power(&mut self, power: GfxPower) {
        self.power = power;
    }
    pub fn set_mode(&mut self, mode: GfxMode) {
        self.mode = mode;
    }
}

#[derive(
    Debug,
    Default,
    PartialEq,
    Eq,
    Copy,
    Clone,
    strum_macros::Display,
    zvariant::Type,
    Serialize,
    Deserialize,
)]
pub enum GfxMode {
    Hybrid,
    Integrated,
    NvidiaNoModeset,
    Vfio,
    AsusEgpu,
    AsusMuxDgpu,
    #[default]
    None,
}

#[derive(
    Debug,
    Default,
    PartialEq,
    Eq,
    Copy,
    Clone,
    strum_macros::Display,
    strum_macros::EnumString,
    zvariant::Type,
    Serialize,
    Deserialize,
)]
#[strum(serialize_all = "kebab-case")]
pub enum GfxPower {
    Active,
    Suspended,
    Off,
    AsusDisabled,
    AsusMuxDiscreet,
    #[default]
    Unknown,
}
impl From<zvariant::OwnedValue> for GfxPower {
    fn from(value: zvariant::OwnedValue) -> Self {
        if_chain! {
            if let Some(s) = value.downcast_ref::<str>();
            if let Ok(s) = GfxPower::from_str(s);
            then {
                s
            } else {
                Self::default()
            }
        }
    }
}

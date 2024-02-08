use super::{xmlgen, BatteryState, BatteryStatus};
use crate::*;
use modules::*;

#[derive(Debug)]
pub struct UPowerModule<'a> {
    proxy: xmlgen::DeviceProxy<'a>,
    state_stream: PropertyStream<'a, BatteryState>,
    percent_stream: PropertyStream<'a, Percent>,
    rate_stream: PropertyStream<'a, f64>,
    current_data: BatteryStatus,
}
impl<'a> Module for UPowerModule<'a> {
    type StartupData = Arc<Connection>;
    #[tracing::instrument(skip(data))]
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        let proxy = xmlgen::DeviceProxy::new(&data).await?;
        let (init_state, state_stream, percent_stream, rate_stream) = join!(
            Self::get_all(&proxy),
            proxy.receive_state_changed(),
            proxy.receive_percentage_changed(),
            proxy.receive_energy_rate_changed(),
        );
        let state = init_state?;
        let me = Self {
            proxy,
            state_stream,
            percent_stream,
            rate_stream,
            current_data: state,
        };
        Ok((me, state.into()))
    }
    #[tracing::instrument(skip(self, sender))]
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        loop {
            select! {
                Some(s) = self.state_stream.next() => {
                    if let Ok(s) = s.get().await {
                        self.current_data.set_state(s);
                        sender.send(self.current_data.into()).await?;
                    }
                }
                Some(p) = self.percent_stream.next() => {
                    if let Ok(p) = p.get().await {
                        self.current_data.set_percentage(p);
                        sender.send(self.current_data.into()).await?;
                    }
                }
                Some(r) = self.rate_stream.next() => {
                    if let Ok(r) = r.get().await {
                        self.current_data.set_rate(r.into());
                        sender.send(self.current_data.into()).await?;
                    }
                }
            }
        }
    }
}
impl UPowerModule<'_> {
    /// Get all the data
    pub async fn get_all(proxy: &xmlgen::DeviceProxy<'_>) -> ModResult<BatteryStatus> {
        let (state, percent, rate) =
            try_join!(proxy.state(), proxy.percentage(), proxy.energy_rate(),)?;
        Ok(BatteryStatus::new(state, percent, rate.into()))
    }
    pub async fn update_all(&mut self) -> ModResult<()> {
        self.current_data = Self::get_all(&self.proxy).await?;
        Ok(())
    }
}

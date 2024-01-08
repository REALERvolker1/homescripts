use crate::modules;
use futures::StreamExt;
mod xmlgen;

pub struct AsusdProxy<'a> {
    pub proxy: xmlgen::DaemonProxy<'a>,
    pub charge_control_end_threshold_stream: zbus::PropertyStream<'a, u8>,
}
impl<'a> AsusdProxy<'a> {
    pub async fn new(
        connection: &'a zbus::Connection,
    ) -> Option<(crate::modules::PropertyProxy, modules::upower::Percent)> {
        let proxy = if let Ok(p) = xmlgen::DaemonProxy::new(connection).await {
            p
        } else {
            return None;
        };

        let (state_raw, charge_control_end_threshold_stream) = tokio::join!(
            proxy.charge_control_end_threshold(),
            proxy.receive_charge_control_end_threshold_changed()
        );

        let state = state_raw.unwrap_or(u8::MAX);

        Some((
            modules::PropertyProxy::Asus(Self {
                proxy,
                charge_control_end_threshold_stream,
            }),
            state,
        ))
    }
    fn name() -> String {
        String::from("asusd (modifies battery)")
    }
}

impl<'a> futures::Stream for AsusdProxy<'a> {
    type Item = modules::WeakStateType<'a>;
    fn poll_next(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        if let std::task::Poll::Ready(Some(s)) =
            self.charge_control_end_threshold_stream.poll_next_unpin(cx)
        {
            return std::task::Poll::Ready(Some(modules::WeakStateType::ChargeControl(s)));
        }
        std::task::Poll::Pending
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, None)
    }
}

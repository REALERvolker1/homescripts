use crate::*;

pub mod datetime;

#[derive(Debug, Default, Clone, strum_macros::Display, strum_macros::EnumIs)]
pub enum RuntimeData {
    String(String),
    #[default]
    None,
}

pub type RunReturn = JoinHandle<NoBruh>;

#[derive(Debug, Default, Clone, strum_macros::Display, strum_macros::EnumIs)]
pub enum MpscData {
    DateTime(Arc<String>),
    #[default]
    None,
}

pub trait Module {
    /// The module runtime
    async fn run(&mut self, runtime_data: RuntimeData, mpsc_sender: Sender<MpscData>) -> NoBruh;
}

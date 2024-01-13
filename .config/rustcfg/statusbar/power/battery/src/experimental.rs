use crate::{types::*, *};
use futures::StreamExt;
use nix::unistd;
use serde::{Deserialize, Serialize};
use small_vec::SmallVec;
use std::{
    pin::Pin,
    task::{Context, Poll},
};
use strum_macros::*;
use zbus::Connection;

// #[async_trait::async_trait]
pub trait Module: Sized {
    fn name(&self) -> &str;
    async fn update(&mut self, payload: RecvType) -> Result<(), ModError>;
    async fn init(connection: &Connection) -> Result<Option<Self>, ModError>;
}

/// The types of data that can be sent and received by modules
///
/// Each type must be serializable and deserializable, and it must be able to be cast `Into<RecvType>`
#[derive(Debug, Default, Clone, EnumDiscriminants, EnumIs)]
pub enum RecvType {
    String(String),
    Percent(Percent),
    Float(f64),
    Multi(Vec<RecvType>),
    /// Custom type for the Power Profiles Daemon module
    PowerProfile(modules::power_profiles::PowerProfileState),
    /// These NotifyStatus types are returned from modules that don't support
    /// property stream watchers, and is used to prompt the module to manually request a refresh.
    NotifyStatus,
    #[default]
    Null,
}
impl From<&str> for RecvType {
    fn from(s: &str) -> Self {
        Self::String(String::from(s))
    }
}
impl From<String> for RecvType {
    fn from(s: String) -> Self {
        Self::String(s)
    }
}
impl From<Percent> for RecvType {
    fn from(p: Percent) -> Self {
        Self::Percent(p)
    }
}
impl From<f64> for RecvType {
    fn from(f: f64) -> Self {
        Self::Float(f)
    }
}

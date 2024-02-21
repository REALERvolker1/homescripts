use crate::prelude::*;

#[derive(Debug, Default, thiserror::Error)]
pub enum Err {
    #[error("SIMD Json Error: {0}")]
    Json(#[from] simd_json::Error),
    #[error("IO Error: {0}")]
    Io(#[from] io::Error),
    #[error("Environment Error: {0}")]
    Env(#[from] env::VarError),
    #[error("Infallible Error")]
    Infallible(#[from] std::convert::Infallible),
    #[error("Unknown Error")]
    #[default]
    Unknown,
}

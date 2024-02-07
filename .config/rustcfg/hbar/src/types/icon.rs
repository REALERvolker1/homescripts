use crate::*;

pub type Icon = char;

#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Hash,
    strum_macros::EnumTryAs,
    derive_more::From,
    derive_more::Display,
)]
pub enum StrIcon {
    #[display(fmt = "{_0}")]
    Char(char),
    #[display(fmt = "{_0}")]
    Str(&'static str),
}

use crate::*;

/// A bool type that can be set to `auto`
#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    PartialOrd,
    Ord,
    Hash,
    Serialize,
    Deserialize,
    strum_macros::Display,
    strum_macros::IntoStaticStr,
    strum_macros::VariantArray,
)]
#[strum(serialize_all = "lowercase")]
pub enum AutoBool {
    True,
    False,
    #[default]
    Auto,
}
impl From<bool> for AutoBool {
    fn from(value: bool) -> Self {
        if value {
            Self::True
        } else {
            Self::False
        }
    }
}
impl Into<bool> for AutoBool {
    fn into(self) -> bool {
        match self {
            Self::False => false,
            _ => true,
        }
    }
}

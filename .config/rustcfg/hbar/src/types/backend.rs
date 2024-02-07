use crate::*;

/// All the backends this bar supports
#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Hash,
    Serialize,
    Deserialize,
    strum_macros::Display,
    strum_macros::VariantArray,
    strum_macros::VariantNames,
)]
#[strum(serialize_all = "kebab-case")]
pub enum Backend {
    Xorg,
    Hyprland,
    WlrootsGeneric,
}
impl Default for Backend {
    fn default() -> Self {
        Self::autodetect().unwrap()
    }
}
impl Backend {
    /// Try to detect the backend. The [`Backend::default`] function uses this internally,
    /// but panics if it fails, so please try to use this instead of that.
    pub fn autodetect() -> Result<Self, env::VarError> {
        if env::var("HYPRLAND_INSTANCE_SIGNATURE").is_ok() {
            Ok(Backend::Hyprland)
        } else if env::var("WAYLAND_DISPLAY").is_ok() {
            Ok(Backend::WlrootsGeneric)
        } else {
            match env::var("DISPLAY") {
                Ok(_) => Ok(Backend::Xorg),
                Err(e) => Err(e),
            }
        }
    }
}

use crate::types::*;
use serde::{Deserialize, Serialize};
use smart_default::SmartDefault;

/// The config for the UPower module
#[derive(Debug, SmartDefault, Serialize, Deserialize)]
pub struct MprisConfig {
    /// Enable the module
    #[default(AutoBool::default())]
    enable: AutoBool,
    /// Whether to show the artist if available
    #[default(false)]
    show_artist: bool,
    /// Whether to show the album if available
    #[default(false)]
    show_album: bool,
    /// Whether to show the song name if available
    #[default(true)]
    show_song: bool,
}

use crate::{types::*, CONFIG};
use hyprland::{
    keyword::{Keyword, OptionValue},
    shared::HyprData,
};

pub async fn hyprland_get_mice_names() -> hyprland::Result<Vec<String>> {
    let hyprland_devices = hyprland::data::Devices::get_async().await?;
    Ok(hyprland_devices.mice.into_iter().map(|m| m.name).collect())
}

pub async fn hyprland_set(touchpad_key: &str, enabled: bool) -> hyprland::Result<()> {
    let touchpad_option = if enabled { 1 } else { 0 };
    Keyword::set_async(touchpad_key, OptionValue::Int(touchpad_option)).await?;
    Ok(())
}

pub async fn hyprland_status(touchpad_key: &str) -> Status {
    if let Ok(r) = Keyword::get_async(touchpad_key).await {
        Status::from_opt(&r.value)
    } else {
        Status::default()
    }
}

/// Returns the correct keyword to query for hyprland touchpad stuff
#[inline]
pub fn hyprland_keyword_touchpad_fmt(touchpad_name: &str) -> String {
    String::from("device:") + touchpad_name + ":enabled"
}

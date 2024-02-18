use super::*;
use hyprland::{keyword::Keyword, shared::HyprData};

#[derive(Debug)]
pub struct Hyprland {
    mice: MouseList,
    touchpad: Mouse,
    touchpad_key: String,
}

impl Backend for Hyprland {
    async fn new() -> Res<Self> {
        let devices = Self::raw_get_pointers().await?;
        let touchpad = config::detect_touchpads(&devices)?;

        // device:"$touchpad_name":enabled
        let mut me = Self {
            mice: HashSet::new(),
            touchpad_key: format!("device:{}:enabled", &touchpad.name),
            touchpad,
        };

        me.refresh_with_mice(devices);
        Ok(me)
    }

    async fn raw_get_pointers() -> Res<Vec<Mouse>> {
        let mice = hyprland::data::Devices::get_async()
            .await?
            .mice
            .into_iter()
            .map(|m| Mouse::from(m))
            .collect();

        Ok(mice)
    }
    // device:"$touchpad_name":enabled
    async fn set_touchpad_status(&self, enabled: Status) -> Res<Status> {
        Keyword::set_async(&self.touchpad_key, enabled.to_bool_optionvalue()).await?;
        // get status right away so I'm sure I'm setting this to the correct value
        let status = self.get_touchpad_status().await?;
        Ok(status)
    }
    async fn get_touchpad_status(&self) -> Res<Status> {
        let statkey = Keyword::get_async(&self.touchpad_key).await?;
        let stat = Status::from_opt(&statkey.value);
        CONFIG.update_statusfile(stat).await?;
        Ok(stat)
    }
    #[inline]
    fn backend() -> Backends {
        Backends::Hyprland
    }
    #[inline]
    fn has_mice(&self) -> bool {
        !self.mice.is_empty()
    }
    #[inline]
    fn cached_mice(&self) -> &MouseList {
        &self.mice
    }
    #[inline]
    fn set_mice(&mut self, mice: MouseList) {
        self.mice = mice
    }
    #[inline]
    fn touchpad(&self) -> &Mouse {
        &self.touchpad
    }
}

use hyprland::{
    keyword::{Keyword, OptionValue},
    shared::Address,
    shared::HyprData,
};

use super::*;

#[derive(Debug)]
pub struct Hyprland {
    pub mice: MouseList,
    pub touchpad: Mouse,
    pub touchpad_key: String,
}
impl std::fmt::Display for Hyprland {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "touchpad: {}\nMice: {}\n",
            self.touchpad,
            self.mice
                .iter()
                .map(|m| m.to_string())
                .collect::<Vec<_>>()
                .join("\n\t")
        )
    }
}
impl Backend for Hyprland {
    async fn new() -> Res<Self> {
        // raw_get_pointers requires &mut self because the xorg backend needs to access a running connection
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
    #[inline]
    fn backend() -> Backends {
        Backends::Hyprland
    }
    fn refresh_with_mice(&mut self, mice: Vec<Mouse>) {
        let mice = mice
            .into_iter()
            .filter(|m| CONFIG.is_mouse(&m.name))
            .filter(|m| &m.address != &self.touchpad.address)
            .map(|m| Mouse::from(m))
            .collect::<HashSet<_>>();

        self.mice = mice;
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
    async fn set_touchpad_status(&self, enabled: Status) -> Res<()> {
        Keyword::set_async(&self.touchpad_key, enabled.to_bool_optionvalue()).await?;
        // get status right away so I'm sure I'm setting this to the correct value
        let _ = self.get_touchpad_status().await?;

        Ok(())
    }
    async fn get_touchpad_status(&self) -> Res<Status> {
        let statkey = Keyword::get_async(&self.touchpad_key).await?;
        let stat = Status::from_opt(&statkey.value);
        // update statusfile
        CONFIG.update_statusfile(stat).await?;
        Ok(stat)
    }
    #[inline]
    fn has_mice(&self) -> bool {
        !self.mice.is_empty()
    }
    async fn status_monitor_inner(&mut self) -> Res<()> {
        self.refresh_mice().await?;
        let old_status = Status::from_bool(self.has_mice());
        let status = old_status.toggle();
        self.set_touchpad_status(status).await?;
        eprintln!("Changed pointer status from {} to {}", old_status, status);

        Ok(())
    }
}

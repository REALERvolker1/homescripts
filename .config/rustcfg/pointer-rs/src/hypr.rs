use super::*;
use hyprland::{keyword::Keyword, shared::HyprData};

#[derive(Debug)]
pub struct Hyprland {
    conf: Conf,
    mice: MouseList,
    touchpad: Mouse,
}

pub const TOUCHPAD_VARIABLE: &str = "$TOUCHPAD_ENABLED";
pub const TOUCHPAD_STATUS_PATH: &str = "";

impl Backend for Hyprland {
    async fn new(conf: Conf) -> Res<Self> {
        let devices = Self::raw_get_pointers().await?;
        let touchpad = conf.detect_touchpads(&devices)?;

        // old meethod: device:"$touchpad_name":enabled
        // new method in config file:
        //
        // $TOUCHPAD_ENABLED = true
        // device {
        //     name = asup1205:00-093a:2003-touchpad
        //     enabled = $TOUCHPAD_ENABLED
        // }
        //
        let mut me = Self {
            conf,
            mice: HashSet::new(),
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
        println!("setting");
        tokio::fs::write()
        // does not work
        // Keyword::set_async(TOUCHPAD_VARIABLE, enabled.to_bool_optionvalue()).await?;
        // get status right away so I'm sure I'm setting this to the correct value
        // let status = self.get_touchpad_status().await?;
        // getting status is broken with the new device config method. Just assume it succeeded
        let status = enabled;
        Ok(status)
    }
    async fn get_touchpad_status(&self) -> Res<Status> {
        let statkey = Keyword::get_async(TOUCHPAD_VARIABLE).await?;
        let stat = Status::from_opt(&statkey.value);
        self.conf.update_statusfile(stat).await?;
        Ok(stat)
    }
    #[inline]
    fn conf(&self) -> &Conf {
        &self.conf
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

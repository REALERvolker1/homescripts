use super::*;
use tokio::process;

#[derive(Debug, Default)]
pub struct Xorg {
    pub mice: MouseList,
    pub touchpad: Device,
    pub touchpad_key: usize,
}
impl Backend for Xorg {
    async fn new() -> Res<Self> {
        // raw_get_pointers requires &mut self because the xorg backend needs to access a running connection
        let devices = Self::raw_get_pointers().await?;

        let touchpad = config::detect_touchpads(&devices)?;

        // device:"$touchpad_name":enabled

        let mut me = Self {
            mice: Rc::new(HashSet::new()),
            touchpad_key: touchpad.get_id_x11()?,
            touchpad,
        };

        me.refresh_with_mice(devices);

        Ok(me)
    }
    fn backend() -> Backends {
        Backends::Xorg
    }
    fn refresh_with_mice(&mut self, mice: Vec<Device>) {
        let mice = mice
            .into_iter()
            .filter(|m| m.is_mouse())
            .filter(|m| m != &self.touchpad)
            .collect::<HashSet<_>>();

        self.mice = Rc::new(mice);
    }

    async fn raw_get_pointers() -> Res<Vec<Device>> {
        let mice = hyprland::data::Devices::get_async()
            .await?
            .mice
            .into_iter()
            .map(|m| Device::from_hyprland_mouse(m))
            .collect();

        Ok(mice)
    }
    // device:"$touchpad_name":enabled
    async fn set_touchpad_status(&self, enabled: Status) -> Res<()> {
        Keyword::set_async(&self.touchpad_key, enabled.to_bool_optionvalue()).await?;
        Ok(())
    }
    async fn get_touchpad_status(&self) -> Res<Status> {
        let stat = Keyword::get_async(&self.touchpad_key).await?;
        Ok(Status::from_opt(&stat.value))
    }
    fn has_mice(&self) -> bool {
        !self.mice.is_empty()
    }
}

/*
pub struct Xorg {
    pub connection: RustConnection,
    pub display: usize,
    pub mice: MouseList,
    pub touchpad: Device,
}
impl Backend for Xorg {
    fn backend() -> Backends {
        Backends::Xorg
    }
    async fn new() -> Res<Self> {
        let current_display = env::var("DISPLAY")?;
        let (conn, display, drive) = RustConnection::connect(Some(&current_display)).await?;
        drive.await?;

        let mut me = Self {
            connection: conn,
            display,
            mice: Rc::new(HashSet::new()),
            touchpad: Device::default(),
        };

        let devices = me.raw_get_pointers().await?;
        me.touchpad = config::detect_touchpads(&devices)?;
        me.refresh_with_mice(devices);

        Ok(me)
    }
    async fn raw_get_pointers(&self) -> Res<Vec<Device>> {
        let device_req = self.connection.xinput_list_input_devices().await?;
        let device_reply = device_req.reply().await?;

        // x11 splits this up for some reason, so we need to loop through it like this
        let names = device_reply.names.iter();
        let devinfos = device_reply.devices.iter();

        let devices = names
            .zip(devinfos)
            .filter(|m| m.1.device_use == xinput::DeviceUse::IS_X_POINTER)
            .map(|(name, info)| Device {
                name: String::from_utf8_lossy(&name.name).to_string(),
                id: DeviceId::X11Id(info.device_id),
            })
            .collect();

        Ok(devices)
    }
    fn has_mice(&self) -> bool {
        !self.mice.is_empty()
    }
    fn refresh_with_mice(&mut self, mice: Vec<Device>) {
        let mice = mice
            .into_iter()
            .filter(|m| m.is_mouse())
            .filter(|m| m != &self.touchpad)
            .collect::<HashSet<_>>();

        self.mice = Rc::new(mice);
    }
    async fn get_touchpad_status(&self) -> Res<Status> {
        let query = self.connection.libin
        let state = query.reply().await?;

        state.classes.
    }
}
*/

use tokio::process::{self, Child};

use crate::{config::*, *};

macro_rules! is_charging {
    ($state:expr) => {
        match $state {
            1 | 4 | 5 | 6 => true,
            _ => false,
        }
    };
}

#[derive(Debug)]
pub struct State {
    percent: f64,
    is_plugged: bool,
    stdout: io::Stdout,
    conn: zbus::Connection,
    battery_last_state: BatteryState,
    /// Keep my dGPU from going to sleep
    should_run_nvidia_smi: bool,
    nvidia_smi_process: Option<Child>,
    max_brightness: u32,
}
impl State {
    pub async fn new(
        conn: zbus::Connection,
        percent: f64,
        state: u32,
        should_run_nvidia_smi: bool,
    ) -> Self {
        Self {
            percent,
            is_plugged: is_charging!(state),
            stdout: io::stdout(),
            conn,
            battery_last_state: BatteryState::default(),
            should_run_nvidia_smi,
            nvidia_smi_process: None,
            max_brightness: config::get_max_brightness().await,
        }
    }
    #[inline]
    pub async fn write(&mut self, str: String) -> io::Result<()> {
        self.stdout.write_all((str + "\n").as_bytes()).await
    }
    #[inline]
    pub async fn update_percent(&mut self, percent: f64) -> Res {
        if self.is_plugged {
            return Ok(());
        }

        let get_state = BatteryState::from_percent(percent);
        if get_state == self.battery_last_state {
            return Ok(());
        }

        self.battery_last_state = get_state;
        self.percent = percent;

        self.run_cmd().await?;
        Ok(())
    }
    #[inline]
    pub async fn update_is_plugged(&mut self, state: u32) -> Res {
        if is_charging!(state) && self.battery_last_state != BatteryState::Plugged {
            self.battery_last_state = BatteryState::Plugged;
            self.run_cmd().await?;
        }
        Ok(())
    }
    pub async fn run_cmd(&mut self) -> Res {
        let config = match self.battery_last_state {
            BatteryState::Plugged => {
                self.nvidia_smi().await;
                AC_CONFIG
            }
            BatteryState::Good
        }
        Ok(())
    }
    async fn nvidia_smi(&mut self) {
        if self.nvidia_smi_process.is_none() && self.should_run_nvidia_smi {
            self.nvidia_smi_process = match process::Command::new("nvidia-smi").arg("-l").spawn() {
                Ok(p) => Some(p),
                Err(e) => {
                    self.write(e.to_string()).unwrap_or_else(|_| ()).await;
                    None
                }
            }
        }
    }
    async fn kill_nvidia_smi(&mut self) {
        if let Some(p) = self.nvidia_smi_process.as_mut() {
            match p.kill().await {
                Ok(_) => (),
                Err(e) => {
                    self.write(e.to_string()).unwrap_or_else(|_| ()).await;
                }
            }
        }
    }
    async fn set_brightness(&self, value: u32) -> Res {
        self.conn
            .call_method(
                Some("org.freedesktop.login1"),
                "/org/freedesktop/login1/session/auto",
                Some("org.freedesktop.login1.Session"),
                "SetBrightness",
                &("backlight", BACKLIGHT, (value * self.max_brightness) as u32),
            )
            .await?;

        Ok(())
    }
}

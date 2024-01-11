use futures::StreamExt;
// use std::str::FromStr;
use serde::{Deserialize, Serialize};
use std::error::Error;
use tokio;
use zbus;

mod battery;
mod cfg;
mod gfx;
mod powerprofile;
mod xmlgen;

use crate::xmlgen::gfxproxy;
use crate::xmlgen::powerprofilesproxy;
use crate::xmlgen::upowerproxy;

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
struct State {
    config: cfg::Config,

    battery_percentage: u8,
    battery_state: battery::BatteryState,
    battery_draw: f64,

    power_profile: powerprofile::PowerProfile,

    gfx_mode: gfx::GfxMode,
    gfx_power: gfx::GfxPower,
}

// TODO: Make this more modular, maybe separate out the logic
impl State {
    async fn new(
        conn: &zbus::Connection,
        conf: cfg::Config,
    ) -> zbus::Result<(
        Self,
        powerprofilesproxy::PowerProfilesProxy,
        upowerproxy::DeviceProxy,
        gfxproxy::DaemonProxy,
    )> {
        let result_proxies = tokio::try_join!(
            powerprofilesproxy::PowerProfilesProxy::new(conn),
            upowerproxy::DeviceProxy::new(conn),
            gfxproxy::DaemonProxy::new(conn)
        );

        let (powerprofile_proxy, battery_proxy, gfx_proxy);
        match result_proxies {
            Ok((f, s, t)) => (powerprofile_proxy, battery_proxy, gfx_proxy) = (f, s, t),
            Err(e) => panic!("Could not connect to all dbus members! {}", e),
        }

        let result_props = tokio::try_join!(
            battery_proxy.percentage(),
            battery_proxy.state(),
            battery_proxy.energy_rate(),
            powerprofile_proxy.active_profile(),
            gfx_proxy.mode(),
            gfx_proxy.power()
        );
        let (
            battery_percentage_part,
            battery_state_part,
            battery_draw_part,
            power_profile_part,
            gfx_mode,
            gfx_power,
        );
        match result_props {
            Ok((p, s, d, a, m, pwr)) => {
                (
                    battery_percentage_part,
                    battery_state_part,
                    battery_draw_part,
                    power_profile_part,
                    gfx_mode,
                    gfx_power,
                ) = (p, s, d, a, m, pwr)
            }
            Err(e) => panic!("Failed to initialize all required values! {}", e),
        }

        Ok((
            Self {
                config: conf,
                battery_percentage: battery_percentage_part.floor() as u8,
                battery_state: battery_state_part.try_into().unwrap_or_default(),
                battery_draw: battery_draw_part,
                power_profile: power_profile_part.as_str().try_into().unwrap_or_default(),
                gfx_mode,
                gfx_power,
            },
            powerprofile_proxy,
            battery_proxy,
            gfx_proxy,
        ))
    }

    fn update_percent(&mut self, percent: u8) {
        if percent != self.battery_percentage {
            self.battery_percentage = percent;
            self.print();
        }
    }
    fn update_state(&mut self, state: battery::BatteryState) {
        if state != self.battery_state {
            self.battery_state = state;
            self.print();
        }
    }
    fn update_draw(&mut self, draw: f64) {
        if draw != self.battery_draw {
            self.battery_draw = draw;
            self.print();
        }
    }
    fn update_powerprofile(&mut self, profile: powerprofile::PowerProfile) {
        if profile != self.power_profile {
            self.power_profile = profile;
            self.print();
        }
    }
    fn update_gfx_power(&mut self, pwr: gfx::GfxPower) {
        if pwr != self.gfx_power {
            self.gfx_power = pwr;
            self.print();
        }
    }

    fn textfmt(&self) -> String {
        let draw_string = match self.battery_state {
            battery::BatteryState::Charging
            | battery::BatteryState::Discharging
            | battery::BatteryState::Unknown => format!(" {:.2}W", self.battery_draw),
            _ => "".to_string(),
        };
        format!(
            "{}{} {} {}%{}",
            powerprofile::powerprofile_icon(self.power_profile),
            gfx::gfx_icon(self.gfx_mode, self.gfx_power),
            battery::battery_icon(self.battery_state, self.battery_percentage),
            self.battery_percentage,
            draw_string
        )
    }

    fn print(&self) {
        match self.config.output_type {
            cfg::OutputType::Stdout => println!("{}", self.textfmt()),
            cfg::OutputType::Waybar => println!(
            "{{\"text\": \"{}\", \"tooltip\": \"State: {}, Percentage: {}%, Energy Rate: {:.2}W, Power profile: {}, GFX mode: {}, GFX status: {}\", \"class\": \"{}\", \"percentage\": {}}}",
            self.textfmt(),
            self.battery_state,
            self.battery_percentage,
            self.battery_draw, // State: {}, Percentage: {}%, Energy Rate: {:.2}W
            self.power_profile,
            self.gfx_mode,
            self.gfx_power,
            self.battery_state,
            self.battery_percentage
        ),
        }
    }
}

impl Default for State {
    fn default() -> Self {
        Self {
            config: cfg::Config::default(),
            battery_percentage: 128,
            battery_state: battery::BatteryState::default(),
            battery_draw: 420.69,
            power_profile: powerprofile::PowerProfile::default(),
            gfx_mode: gfx::GfxMode::default(),
            gfx_power: gfx::GfxPower::default(),
        }
    }
}

// #[tokio::main]
#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn Error>> {
    let conn = zbus::Connection::system().await?;

    let program_config = cfg::Config::from_args().unwrap_or_default();

    let (mut state, powerprofile_proxy, battery_proxy, gfx_proxy) =
        State::new(&conn, program_config).await?;

    // println!("{:#?}", state);
    state.print();

    let mut percentage_stream = battery_proxy.receive_percentage_changed().await;
    let mut state_stream = battery_proxy.receive_state_changed().await;
    let mut draw_stream = battery_proxy.receive_energy_rate_changed().await;
    let mut power_profile_stream = powerprofile_proxy.receive_active_profile_changed().await;
    let mut gfx_notify_stream = gfx_proxy.receive_notify_gfx_status().await?;

    loop {
        // requires `use futures::StreamExt;`
        tokio::select! {
            Some(percent_change) = percentage_stream.next() => {
                state.update_percent(percent_change.get().await?.round() as u8);
            }
            Some(state_change) = state_stream.next() => {
                state.update_state(battery::BatteryState::try_from(state_change.get().await?).unwrap_or_default());
            }
            Some(draw_change) = draw_stream.next() => {
                state.update_draw(draw_change.get().await?);
            }
            Some(powerprofile_change) = power_profile_stream.next() => {
                let profile = powerprofile_change.get().await?;
                state.update_powerprofile(powerprofile::PowerProfile::try_from(profile.as_str()).unwrap_or_default());
            }
            Some(_gfx_notify_change) = gfx_notify_stream.next() => {
                // state.update_gfx_mode(gfx_change.get().await?)
                // let gfx_power = ;
                state.update_gfx_power(gfx_proxy.power().await?);
            }
        }
    }

    // Ok(())
}

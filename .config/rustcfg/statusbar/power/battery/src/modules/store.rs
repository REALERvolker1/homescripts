//! To add properties to listen to, edit this file! Also check out mod.rs
use crate::modules::*;
// Good logging is always good to have
use tracing::{debug, info, warn};

pub type ModuleLoaderType<'a> = (
    PropertyStore,
    Vec<ProxyType<'a>>,
    Vec<ListenerType<'a>>,
    Option<supergfxd::xmlgen::DaemonProxy<'a>>,
);

/// A complement to main(). Edit this function to add more modules.
#[tracing::instrument(level = "debug", skip(connection))]
pub async fn load_modules<'a>(
    connection: &zbus::Connection,
    // config: config::Config,
) -> Result<ModuleLoaderType<'a>, ModError> {
    info!("Loading modules");
    let mut global_state = store::PropertyStore::default();
    let mut proxies = Vec::new();
    let mut listeners = Vec::new();

    let (maybe_battery, maybe_power_profile) = tokio::join!(
        upower::create_upower_module(connection),
        power_profiles::create_power_profiles_module(connection),
    );

    if let Ok(bat) = maybe_battery {
        proxies.push(bat.0);
        global_state.insert(bat.1)?;
        global_state.insert(bat.2)?;
        global_state.insert(bat.3)?;
        listeners.push(bat.4);
        listeners.push(bat.5);
        listeners.push(bat.6);
        info!("Loaded Battery module");
        if let Ok(asus) = asusd::create_power_profiles_module(connection).await {
            proxies.push(asus.0);
            global_state.insert(asus.1)?;
            listeners.push(asus.2);
            info!("Loaded advanced charge limit monitoring");
        }
        // } else {
        //     global_state.insert(StateType::ChargeControl(config.charge_end_threshold))?;
        // }
    }
    if let Ok(power) = maybe_power_profile {
        proxies.push(power.0);
        global_state.insert(power.1)?;
        listeners.push(power.2);
        info!("Loaded Power-Profiles-Daemon module");
    }

    // A workaround for supergfxd being weird
    let sgfx_proxy = if let Ok(sgfx) = supergfxd::create_supergfxd_module(connection).await {
        global_state.supergfx_icon = Some(sgfx.2.to_owned());
        if let Some(p) = sgfx.0 {
            if let Some(s) = sgfx.1 {
                listeners.push(ListenerType::SuperGFXPower(s));
                info!("Loaded SuperGFX module");
                Some(p)
            } else {
                None
            }
        } else {
            None
        }
    } else {
        None
    };

    Ok((global_state, proxies, listeners, sgfx_proxy))
}
type BS = upower::BatteryState;
/// The global state. There should only be one of this at any given time.
#[derive(Debug, Default)]
pub struct PropertyStore {
    // pub config: crate::config::Config,
    pub battery_state: Option<upower::BatteryState>,
    pub battery_percentage: Option<upower::Percent>,
    pub battery_rate: Option<f64>,
    pub charge_control_end: upower::Percent,
    pub class: Class,
    pub power_profile: Option<power_profiles::PowerProfileState>,
    pub supergfx_icon: Option<String>,
}
impl PropertyStore {
    /// The function that generates the pretty-print string
    pub fn string(&self) -> String {
        let gfx_icon = if let Some(s) = &self.supergfx_icon {
            (s.as_str(), " ")
        } else {
            ("", "")
        };
        let power_profile = if let Some(b) = self.power_profile {
            b.icon()
        } else {
            ""
        };
        // I am doing it this way for speed
        let battery_status = if let Some(state) = self.battery_state {
            if let Some(perc) = self.battery_percentage {
                let icon = upower::battery_icon(perc, state);
                // determine whether to show rate
                if let Some(rate) = self.battery_rate {
                    if rate != 0.0 {
                        match state {
                            BS::FullyCharged | BS::Empty | BS::PendingDischarge => {
                                format!("{} {}", icon, perc)
                            }
                            _ => format!("{} {} {:.2}W", icon, perc, rate),
                        }
                    } else {
                        // Don't show a bunch of spammy zeroes
                        info!("Rate is zero, skipping rate display");
                        format!("{} {}", icon, perc)
                    }
                } else {
                    warn!("Incomplete battery module: No battery rate");
                    format!("{} {}", icon, perc)
                }
            } else {
                warn!("Incomplete battery module: No battery percentage");
                "".to_owned()
            }
        } else {
            "".to_owned()
        };
        format!(
            "{}{}{} {}",
            gfx_icon.0, gfx_icon.1, power_profile, &battery_status
        )
    }
    /// Insert values into the global state, without updating other struct members.
    ///
    /// Used for initialization when shared data may not be available just yet.
    pub fn insert(&mut self, data: StateType) -> Result<(), ModError> {
        match data {
            StateType::BatteryState(s) => self.battery_state = Some(s),
            StateType::BatteryPercentage(s) => self.battery_percentage = Some(s),
            StateType::BatteryRate(s) => self.battery_rate = Some(s),
            StateType::PowerProfile(s) => self.power_profile = Some(s),
            // StateType::SuperGFXPower(s) => self.supergfx_power = Some(s),
            StateType::ChargeControl(s) => self.charge_control_end = s,
            _ => return Err(ModError::StateAssignmentError(data)),
        }
        info!("Successfully inserted {:?} into global state", data);
        Ok(())
    }
    /// Update the global state, along with any other potential side effects and whatnot
    ///
    /// Used at runtime, when shared data is available.
    pub fn update(&mut self, data: StateType) -> () {
        if let Err(e) = self.insert(data) {
            warn!("{}", e);
            return;
        }
        if let Err(e) = self.update_class() {
            warn!("{}", e);
            return;
        }
    }
    /// Update the supergfx icon. Yet another hack.
    #[tracing::instrument]
    pub async fn update_sgfx_icon(&mut self, sgfx_proxy: &supergfxd::xmlgen::DaemonProxy<'_>) {
        self.supergfx_icon = Some(supergfxd::get_icon(&sgfx_proxy).await.to_owned());
    }
    /// Update the waybar class.
    ///
    /// Printed to stderr when in console mode.
    pub fn update_class(&mut self) -> Result<(), ModError> {
        let state = if let Some(s) = self.battery_state {
            s
        } else {
            return Err(ClassUpdateErrorType::BatteryState.err());
        };
        let rate = if let Some(s) = self.battery_rate {
            s
        } else {
            return Err(ClassUpdateErrorType::BatteryRate.err());
        };
        let percent = if let Some(s) = self.battery_percentage {
            s
        } else {
            return Err(ClassUpdateErrorType::BatteryPercentage.err());
        };

        let is_charging = state == upower::BatteryState::Charging;
        let is_above_threshold = percent > self.charge_control_end;
        let is_low_power = percent.u() <= 10; //self.config.low_power

        self.class = if is_charging {
            if is_above_threshold {
                Class::ChargingAboveThreshold
            } else if is_low_power {
                Class::ChargingLowPower
            } else if rate > 80.0 {
                //self.config.ac_high_draw_threshold
                Class::ChargingHighDraw
            } else {
                Class::Charging
            }
        } else {
            if is_above_threshold {
                Class::DischargingAboveThreshold
            } else if is_low_power {
                Class::DischargingLowPower
            } else if rate > 80.0 {
                // self.config.ac_high_draw_threshold
                Class::DischargingHighDraw
            } else {
                Class::Discharging
            }
        };

        Ok(())
    }
}

/// The class of the waybar module(s)
#[derive(Debug, Copy, Clone, PartialEq, Eq, Default, strum_macros::Display)]
pub enum Class {
    Charging,
    Discharging,
    ChargingHighDraw,
    DischargingHighDraw,
    ChargingLowPower,
    DischargingLowPower,
    ChargingAboveThreshold,
    DischargingAboveThreshold,
    /// Everything is okay
    #[default]
    None,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, strum_macros::Display)]
pub enum ClassUpdateErrorType {
    BatteryState,
    BatteryRate,
    BatteryPercentage,
}
impl ClassUpdateErrorType {
    pub fn err(&self) -> ModError {
        ModError::ClassUpdateError(*self)
    }
}

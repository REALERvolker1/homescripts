use crate::settings::*;

/// The global state.
///
/// You must call the print function manually -- it will not be called when the values are changed.
#[derive(Debug, Default, Clone, PartialEq)]
pub struct State {
    battery_rate: Cell<Option<BatRateType>>,
    battery_percent: Cell<u8>,
    battery_icon: Cell<&'static str>,
    battery_state: Cell<BatteryState>,
    pub sgfx_icon: Cell<Icon>,
    sgfx_active: Cell<bool>,
    pp_icon: Cell<Icon>,
    class: Cell<CssClass>,
}
impl State {
    pub fn print(&self) {
        let percent = self.battery_percent.get();
        let class = self.class.get();

        let rate_string = match self.battery_rate.get() {
            Some(r) => format!(" {:.2}W", r),
            None => String::new(),
        };

        println!(
            "{{\"text\":\"{}{} {} {}%{}\",\"class\":\"{class:?}\",\"percentage\": {percent}}}",
            self.pp_icon.get(),
            self.sgfx_icon.get(),
            self.battery_icon.get(),
            percent,
            rate_string
        );
        eprintln!("{:?}", self);
    }

    pub fn set_battery_rate(&self, rate: BatRateType) {
        let rate_type = if rate.is_normal() && rate > 0.0 {
            Some(rate)
        } else {
            None
        };

        self.battery_rate.set(rate_type);
        self.derive_class();
    }

    pub fn set_battery_state(&self, state: BatStateType) {
        eprintln!("state: {}", state);
        self.battery_state.set(BatteryState::from_dbus(state));
        self.derive_battery_icon();
        self.derive_class();
    }
    /// TODO: Calculate css class

    pub fn set_percent(&self, percent: BatPercentType) {
        let unsigned = percent.round() as u8;
        self.battery_percent.set(unsigned);
        self.derive_battery_icon();
    }

    pub fn derive_battery_icon(&self) {
        self.battery_icon.set(battery_icon(
            self.battery_state.get(),
            self.battery_percent.get(),
        ));
    }

    pub fn set_sgfx(&self, power: SgfxPowerType) {
        let (icon, is_active) = match power {
            0 => ('󰒇', true),  // Active
            1 => ('󰒆', false), // Suspended
            2 => ('󰒅', false), // Off
            3 => ('󰒈', false), // AsusDisabled
            4 => ('󰾂', true),  // AsusMuxDiscreet
            _ => ('󰳤', false), // Unknown
        };
        self.sgfx_icon.set(icon);
        self.sgfx_active.set(is_active);
        self.derive_class();
    }

    pub fn set_power_profile(&self, profile: PprofType) {
        let icon = match profile.to_ascii_lowercase().as_str() {
            "power-saver" => '󰌪',
            "balanced" => '󰛲',
            "performance" => '󱐋',
            _ => 'P',
        };

        self.pp_icon.set(icon);
    }

    pub fn derive_class(&self) {
        self.class.set(CssClass::derive(
            self.battery_state.get(),
            self.battery_rate.get(),
            self.sgfx_active.get(),
        ));
    }
}

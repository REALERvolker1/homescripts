// use upower_dbus::UPowerProxy;
use zbus::{
    self,
    dbus_proxy,
    zvariant::OwnedValue
};

// #[derive(Debug)]
// struct Device {
//     has_history: bool,
//     has_statistics: bool,
//     is_present: bool,
//     is_rechargeable: bool,
//     online: bool,
//     power_supply: bool,
//     capacity: f64,
//     energy: f64,
//     energy_empty: f64,
//     energy_full: f64,
//     energy_full_design: f64,
//     energy_rate: f64,
//     luminosity: f64,
//     percentage: f64,
//     temperature: f64,
//     voltage: f64,
//     charge_cycles: i32,
//     time_to_empty: i64,
//     time_to_full: i64,
//     icon_name: String,
//     model: String,
//     native_path: String,
//     serial: String,
//     vendor: String,
//     battery_level: u32,
//     state: u32,
//     technology: u32,
//     my_type: u32,
//     warning_level: u32,
//     upate_time: u64
// }

#[derive(Debug, Copy, Clone, OwnedValue, PartialEq)]
#[repr(u32)]
pub enum BatteryType {
    Unknown = 0,
    LinePower = 1,
    Battery = 2,
    Ups = 3,
    Monitor = 4,
    Mouse = 5,
    Keyboard = 6,
    Pda = 7,
    Phone = 8,
}

#[derive(Debug, Copy, Clone, OwnedValue, PartialEq)]
#[repr(u32)]
pub enum BatteryState {
    Unknown = 0,
    Charging = 1,
    Discharging = 2,
    Empty = 3,
    FullyCharged = 4,
    PendingCharge = 5,
    PendingDischarge = 6,
}

#[derive(Debug, Copy, Clone, OwnedValue, PartialEq)]
#[repr(u32)]
pub enum BatteryLevel {
    Unknown = 0,
    None = 1,
    Low = 3,
    Critical = 4,
    Normal = 6,
    High = 7,
    Full = 8,
}

#[dbus_proxy(
    interface = "org.freedesktop.UPower.Device",
    default_service = "org.freedesktop.UPower",
)]

trait Device {
    #[dbus_proxy(property)]
    fn battery_level(&self) -> zbus::Result<BatteryLevel>;

    #[dbus_proxy(property)]
    fn capacity(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy_empty(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy_full(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy_full_design(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn energy_rate(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn has_history(&self) -> zbus::Result<bool>;

    #[dbus_proxy(property)]
    fn has_statistics(&self) -> zbus::Result<bool>;

    #[dbus_proxy(property)]
    fn icon_name(&self) -> zbus::Result<String>;

    #[dbus_proxy(property)]
    fn is_present(&self) -> zbus::Result<bool>;

    #[dbus_proxy(property)]
    fn is_rechargeable(&self) -> zbus::Result<bool>;

    #[dbus_proxy(property)]
    fn luminosity(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn model(&self) -> zbus::Result<String>;

    #[dbus_proxy(property)]
    fn native_path(&self) -> zbus::Result<String>;

    #[dbus_proxy(property)]
    fn online(&self) -> zbus::Result<bool>;

    #[dbus_proxy(property)]
    fn percentage(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property)]
    fn power_supply(&self) -> zbus::Result<bool>;

    fn refresh(&self) -> zbus::Result<()>;

    #[dbus_proxy(property)]
    fn serial(&self) -> zbus::Result<String>;

    #[dbus_proxy(property)]
    fn state(&self) -> zbus::Result<BatteryState>;

    #[dbus_proxy(property)]
    fn temperature(&self) -> zbus::Result<f64>;

    #[dbus_proxy(property, name = "Type")]
    fn type_(&self) -> zbus::Result<BatteryType>;

    #[dbus_proxy(property)]
    fn vendor(&self) -> zbus::Result<String>;

    #[dbus_proxy(property)]
    fn voltage(&self) -> zbus::Result<f64>;
}

// assume_defaults = false
// pub trait Device {
//     fn refresh(&self) -> zbus::Result<()>;

//     #[dbus_proxy(property)]
//     fn type_(&self) -> zbus::Result<BatteryType>;

//     #[dbus_proxy(property)]
//     fn online(&self) -> zbus::Result<bool>;

//     #[dbus_proxy(property)]
//     fn power_supply(&self) -> zbus::Result<bool>;

//     #[dbus_proxy(property)]
//     fn percentage(&self) -> zbus::Result<f64>;

//     #[dbus_proxy(property)]
//     fn energy_rate(&self) -> zbus::Result<f64>;

//     #[dbus_proxy(property)]
//     fn state(&self) -> zbus::Result<BatteryState>;
// }

#[dbus_proxy(
    interface = "org.freedesktop.UPower",
    assume_defaults = true
)]
trait UPower {
    /// EnumerateDevices method
    fn enumerate_devices(&self) -> zbus::Result<Vec<zbus::zvariant::OwnedObjectPath>>;

    /// GetCriticalAction method
    fn get_critical_action(&self) -> zbus::Result<String>;

    /// GetDisplayDevice method
    #[dbus_proxy(object = "Device")]
    fn get_display_device(&self);

    /// DeviceAdded signal
    #[dbus_proxy(signal)]
    fn device_added(&self, device: zbus::zvariant::ObjectPath<'_>) -> zbus::Result<()>;

    /// DeviceRemoved signal
    #[dbus_proxy(signal)]
    fn device_removed(&self, device: zbus::zvariant::ObjectPath<'_>) -> zbus::Result<()>;

    /// DaemonVersion property
    #[dbus_proxy(property)]
    fn daemon_version(&self) -> zbus::Result<String>;

    /// LidIsClosed property
    #[dbus_proxy(property)]
    fn lid_is_closed(&self) -> zbus::Result<bool>;

    /// LidIsPresent property
    #[dbus_proxy(property)]
    fn lid_is_present(&self) -> zbus::Result<bool>;

    /// OnBattery property
    #[dbus_proxy(property)]
    fn on_battery(&self) -> zbus::Result<bool>;
}

#[derive(Debug, Copy, Clone, PartialEq)]
pub enum PrintType {
    Waybar,
    JSON,
    Simple,
    Complex,
}

#[derive(Debug, Copy, Clone)]
pub struct Battery {
    pub print_type: PrintType,
    pub charging: bool,
    pub percentage: i64,
    pub energy_rate: f64,
    pub state: BatteryState,
    pub icon: &'static str,
}

impl Battery {
    pub fn print(&self) {
        match self.print_type {
            PrintType::Waybar => {
                let main_text: String;
                match self.state {
                    BatteryState::Charging => {
                        main_text = format!("{} {:.1}%", self.icon, self.percentage);
                    },
                    BatteryState::Discharging => {
                        main_text = format!("{} {:.1}% {:.2}W", self.icon, self.percentage, self.energy_rate);
                    },
                    BatteryState::Empty => {
                        main_text = format!("{} {:.1}% {:.2}W", self.icon, self.percentage, self.energy_rate);
                    },
                    BatteryState::FullyCharged => {
                        main_text = format!("{}", self.icon);
                    },
                    BatteryState::PendingCharge => {
                        main_text = format!("{} {}%", self.icon, self.percentage);
                    },
                    BatteryState::PendingDischarge => {
                        main_text = format!("{} {}%", self.icon, self.percentage);
                    },
                    BatteryState::Unknown => {
                        main_text = format!("{}", self.icon);
                    }
                };// \"alt\": \"{}\",
                let tooltip_text = format!("Charging: {}, Percentage: {}%, Energy Rate: {:.2}W, Icon: {}", self.charging, self.percentage, self.energy_rate, self.icon);
                println!("{{\"text\": \"{}\", \"tooltip\": \"{}\", \"class\": \"{:?}\", \"percentage\": {}}}", main_text, tooltip_text, self.state, self.percentage)
            },
            PrintType::JSON => println!("{{\"Charging\": {}, \"Percentage\": {}, \"Energy Rate\": {}, \"State\": \"{:?}\", \"Icon\": \"{}\"}}", self.charging, self.percentage, self.energy_rate, self.state, self.icon),
            PrintType::Simple => println!("{} {:.1}% {:.2}W", self.icon, self.percentage, self.energy_rate),
            PrintType::Complex => println!("Charging: {}, Percentage: {}, Energy Rate: {}, Icon: {}", self.charging, self.percentage, self.energy_rate, self.icon)
        }
    }
    pub fn update_icon(&mut self) {
        let icon = match self.state {
            BatteryState::Charging => {
                match self.percentage {
                    0..=33 => "󱊤",
                    34..=66 => "󱊥",
                    67..=100 => "󱊦",
                    _ => "󰂑"
                }
            },
            BatteryState::Discharging => {
                match self.percentage {
                    0..=33 => "󱊡",
                    34..=66 => "󱊢",
                    67..=100 => "󱊣",
                    _ => "󰂑"
                }
            },
            BatteryState::FullyCharged => "󰁹",
            BatteryState::Empty => "󱃍",
            BatteryState::PendingCharge => "󰂏",
            BatteryState::PendingDischarge => "󰂌",
            _ => "󰂑",
        };
        self.icon = icon
    }
}


// pub fn get_icon(&self) -> String {
//         let percent_int: i64 = self.percentage.round() as i64;
//         let icon = match self.state {
//             BatteryState::Charging => {
//                 match percent_int {
//                     0..=33 => "󱊤",
//                     34..=66 => "󱊥",
//                     67..=100 => "󱊦",
//                     _ => "󰂑"
//                 }
//             },
//             BatteryState::Discharging => {
//                 match percent_int {
//                     0..=33 => "󱊡",
//                     34..=66 => "󱊢",
//                     67..=100 => "󱊣",
//                     _ => "󰂑"
//                 }
//             },
//             BatteryState::FullyCharged => "󰁹",
//             BatteryState::Empty => "󱃍",
//             BatteryState::PendingCharge => "󰂏",
//             BatteryState::PendingDischarge => "󰂌",
//             _ => "󰂑",
//         };
//         icon.to_string()
//     }

use futures_util::TryFutureExt;

use super::BatteryStatus;
use crate::*;

/// convert from µW to W
const POWER_DRAW_DIVISOR: f64 = 1_000_000_000_000.0;

macro_rules! ensure_files {
    ($($file:ident),+) => {
        $(
            let $file = if let Some(f) = $file {
                f
            } else {
                return Err(concat!("Sysfs is missing required file: ", stringify!($file)).into());
            };
        )+
    };
}

#[derive(Debug, Serialize, Deserialize, derive_more::Display)]
#[display(
    fmt = "path:\t{}\ncapacity:\t{}\nstatus:\t{}\n{}",
    "path.display()",
    "capacity.display()",
    "status.display()",
    rate
)]
pub struct SysFs {
    path: PathBuf,
    capacity: PathBuf,
    status: PathBuf,
    rate: PowerRate,
    battery_status: BatteryStatus,
    poll_rate: Duration,
}
impl SysFs {
    /// Read all the files at once, getting a snapshot of the battery status
    #[tracing::instrument(skip(self))]
    pub async fn poll_all_once(&self) -> ModResult<BatteryStatus> {
        let (capacity_str, status_str, rate) = try_join!(
            fs::read_to_string(&self.capacity).map_err(|e| e.into()),
            fs::read_to_string(&self.status).map_err(|e| e.into()),
            self.rate.get_power_draw()
        )?;
        let capacity = Percent::from_str(&capacity_str)?;
        let status = super::BatteryState::from_str(&status_str)?;
        Ok(BatteryStatus::new(status, capacity, rate))
    }
    pub async fn update_self(&mut self) -> ModResult<()> {
        self.battery_status = self.poll_all_once().await?;
        Ok(())
    }
}
impl Module for SysFs {
    type StartupData = super::BatteryConfig;
    #[tracing::instrument(skip(self, sender))]
    async fn run(&mut self, sender: modules::ModuleSender) -> ModResult<()> {
        loop {
            let data = self.poll_all_once().await?;
            let (send_res, _) = join!(sender.send(data.into()), sleep!(self.poll_rate));
            if let Err(e) = send_res {
                return Err(e.into());
            }
        }
    }
    #[tracing::instrument(skip(data))]
    async fn new(data: Self::StartupData) -> ModResult<(Self, modules::ModuleData)> {
        let power_supply = Path::new("/sys/class/power_supply");

        let power_supplies = power_supply
            .read_dir()?
            .filter_map(|e| e.ok())
            .filter(|e| e.file_name().to_string_lossy().starts_with("BAT"))
            .collect_vec();

        // we already know it's no use
        if power_supplies.len() == 0 {
            return Err("No power supplies found".into());
        }

        // let the user choice reign supreme, but fall back.
        let power_dir = if_chain! {
            if let Some(battery_number) = data.sysfs_battery_number.map(|i| i.to_string());
            if let Some(d) = power_supplies.iter().find_or_first(|e| e.file_name().to_string_lossy().ends_with(&battery_number));
            then {
                d.path()
            } else {
                if let Some(d) = power_supplies.iter().next() {
                    d.path()
                } else {
                    // This error should not happen, because we already made sure there's at least one element.
                    return Err("No power supplies found -- secret rare error edition".into());
                }
            }
        };

        macro_rules! ensure_power_files {
            ($($varname:ident = $file:expr);+$(;)?) => {
                $(
                    ensure_power_files!(f = nounwrap $file);
                    let $varname = match f {
                        Ok(f) => f,
                        Err(e) => {
                            return Err(e);
                        }
                    };
                )+
            };
            ($($varname:ident = nounwrap $file:expr);+$(;)?) => {
                $(
                    let filepath = power_dir.join($file);
                    let $varname = if filepath.exists() {
                        Ok(filepath)
                    } else {
                        Err(ModError::from(concat!("Sysfs is missing required file: ", stringify!($file))))
                    };
                )+
            };
        }

        ensure_power_files! {
            capacity = "capacity";
            status = "status";
            voltage_now = "voltage_now";
            current_now = "current_now";
        }
        ensure_power_files! {
            power_now = nounwrap "power_now";
        }

        // ensure_files!(capacity, status);

        let rate = if let Ok(power_now) = power_now {
            PowerRate::Easy(power_now)
        } else {
            PowerRate::Calculate {
                voltage: voltage_now,
                current: current_now,
            }
        };

        let mut inner = Self {
            path: power_dir,
            capacity,
            status,
            rate,
            battery_status: BatteryStatus::default(),
            poll_rate: Duration::from_secs(data.sysfs_poll_rate),
        };
        let polled = inner.poll_all_once().await?;
        inner.battery_status = polled;
        Ok((inner, polled.into()))
    }
}

#[derive(Debug, PartialEq, Eq, derive_more::Display, Deserialize, Serialize)]
pub enum PowerRate {
    /// Calculate the power draw from voltage_now and current_now
    #[display(
        fmt = "voltage_now:\t{}\ncurrent_now:\t{}",
        "voltage.display()",
        "current.display()"
    )]
    Calculate { voltage: PathBuf, current: PathBuf },
    /// Some systems make it easy, and have a `power_now` file that just does everything.
    #[display(fmt = "power_now:\t{}", "_0.display()")]
    Easy(PathBuf),
}
impl PowerRate {
    pub async fn get_power_draw(&self) -> ModResult<FuckingFloat> {
        match self {
            Self::Calculate { voltage, current } => {
                let (voltage_now, current_now) =
                    try_join!(fs::read_to_string(voltage), fs::read_to_string(current))?;

                let voltage_num: f64 = voltage_now.parse()?;
                let current_num: f64 = current_now.parse()?;
                Ok(((voltage_num * current_num) / POWER_DRAW_DIVISOR).into())
            }
            Self::Easy(path) => Ok(fs::read_to_string(path).await?.parse::<f64>()?.into()),
        }
    }
}

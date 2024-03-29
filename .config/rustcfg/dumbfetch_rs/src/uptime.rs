use crate::entry::Entry;

pub fn get_uptime() -> Entry {
    // let uptime_file = undef!(@err std::fs::read_to_string("/proc/uptime"), "Uptime");

    // let decimal = undef!(@opt uptime_file.find('.'), "Uptime");
    // let (uptime_raw, _) = uptime_file.split_at(decimal);
    // let uptime_full = undef!(@err uptime_raw.parse::<u32>(), "Uptime");

    let sysinfo = rustix::system::sysinfo();
    let uptime_full = sysinfo.uptime;
    let hours = uptime_full / 3600;
    let minutes = (uptime_full % 3600) / 60;

    let display = if hours == 0 {
        format!("{minutes}m")
    } else {
        format!("{hours}h {minutes}m")
    };

    Entry::new("Uptime", display)
}

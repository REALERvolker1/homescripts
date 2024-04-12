use std::{io::Write, time::Duration};

use dbus::message::MatchRule;

const POWER_MAP: phf::Map<u32, &'static str> = phf_macros::phf_map! {
    0u32 => "󰒇\n",
    1u32 => "󰒆\n",
    2u32 => "󰒅\n",
};

const MODE_MAP: phf::Map<u32, &'static str> = phf_macros::phf_map! {
    1u32 => "󰰃\n",
    2u32 => "󰰒\n",
    3u32 => "󰰪\n",
    4u32 => "󰯷\n",
    5u32 => "󰰏\n",
};

const IFACE: &str = "org.supergfxctl.Daemon";
const PATH: &str = "/org/supergfxctl/Gfx";

macro_rules! icon {
    ($map:ident, $val:expr, $default:expr) => {
        if let Some(s) = $map.get(&$val) {
            *s
        } else {
            $default
        }
    };
}

pub fn new_main() -> Result<(), Box<dyn std::error::Error>> {
    let conn = dbus::blocking::LocalConnection::new_system()?;
    let proxy = conn.with_proxy(IFACE, PATH, Duration::from_secs(5));

    let mut stdout = std::io::stdout().lock();

    // I made this a macro because I would have needed to fight the borrow checker
    // to make a function out of this, and I wanted those functions to be inlined anyways.
    macro_rules! meth {
        ($method_name:expr) => {
            match proxy.method_call(IFACE, $method_name, ()) {
                Ok((m,)) => m,
                Err(e) => return Err(e.into()),
            }
        };
    }

    let mode = meth!("Mode");
    if let Some(i) = MODE_MAP.get(&mode) {
        stdout.write_all(i.as_bytes())?;
        return Ok(());
    }

    // use eavesdrop because this is the system bus
    let match_rule = MatchRule::new_signal(IFACE, "NotifyGfxStatus").with_eavesdrop();

    // proxy.

    proxy.match_signal(|signal_args: dbus::blocking::stdintf::org_freedesktop_dbus::PropertiesPropertiesChanged, conn, msg| {
        let out = format!("{:?}\n", msg);
        stdout.write(out.as_bytes()).unwrap();

        true
    });
    // proxy.match_start(match_rule, false, |s, me, msg| {
    //     let power = meth!("Power");
    //     let power_icon = icon!(POWER_MAP, power, "󰾂\n");

    //     stdout.write_all(power_icon.as_bytes())?;
    //     stdout.flush()?;

    //     Ok(())
    // });

    let power = meth!("Power");
    let power_icon = icon!(POWER_MAP, power, "󰾂\n");
    println!("{}", power_icon);

    Ok(())
}

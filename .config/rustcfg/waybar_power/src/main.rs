mod settings;
mod state;
mod utils;

use dbus::blocking::stdintf::org_freedesktop_dbus::Properties;

use crate::settings::*;

fn main() -> R<()> {
    let conn = dbus::blocking::LocalConnection::new_system()?;
    let state = Rc::new(state::State::default());

    conn.set_signal_match_mode(true);
    conn.start_receive(
        SUPERGFX_IFACE.match_rule(SGFX_NOTIFY_GFX_STATUS),
        Box::new(|message, _conn| {
            println!("Received message: {:?}", message);
            true
        }),
    );

    compile_error!("TODO: This only matches the first match rule");

    macro_rules! matcher {
        ([$iface:expr] $( rule: $rule:expr, type: $ty:ty, call: $method:tt ),+$(,)?) => {
            $(
                let proxy = $iface.proxy(&conn);
                let current: $ty = proxy.get($iface.interface, $rule)?;
                state.$method(current);
            )+
            matcher!(@uninit [$iface] $( rule: $rule, type: $ty, call: $method ),+);
        };
        (@uninit [$iface:expr] $( rule: $rule:expr, type: $ty:ty, call: $method:tt ),+$(,)?) => {
            $(
                let my_state = Rc::clone(&state);
                conn.add_match($iface.match_rule($rule), move |_: (), _conn, message| {
                    if let Some(msg) = message.get1::<$ty>() {
                        my_state.$method(msg);
                        true
                    } else {
                        eprintln!("Error converting {} message argument into {}: {:?}", stringify!($rule), stringify!($ty), message);
                        false
                    }
                })?;
            )+
        };
    }

    {
        // I only have to watch for sgfx status changes if it is in hybrid mode afaik
        let proxy = SUPERGFX_IFACE.proxy(&conn);
        let mode: R<(SgfxModeType,)> = proxy.method_call(SUPERGFX_IFACE.interface, SGFX_MODE, ());

        match mode.map(|(m,)| sgfx_mode_icon(m)) {
            Ok(Some(i)) => state.sgfx_icon.set(i),
            Ok(None) => {
                let current_power: (SgfxPowerType,) =
                    proxy.method_call(SUPERGFX_IFACE.interface, SGFX_POWER, ())?;
                state.set_sgfx(current_power.0);

                matcher! {
                    @uninit [SUPERGFX_IFACE]
                    rule: SGFX_NOTIFY_GFX_STATUS,
                    type: SgfxPowerType,
                    call: set_sgfx
                }
            }
            Err(e) => eprintln!("Failed to get supergfx mode: {e}"),
        }
    }

    {
        // let proxy = PPROF_IFACE.proxy(&conn);

        // let current_power: PprofType = proxy.get(PPROF_IFACE.interface, PPROF_PROFILE)?;
        // state.set_power_profile(current_power);

        matcher! {
            [PPROF_IFACE]
            rule: PPROF_PROFILE,
            type: PprofType,
            call: set_power_profile
        }
    }

    {
        // let proxy = BAT_IFACE.proxy(&conn);

        // let current_rate: BatRateType = proxy.get(BAT_IFACE.interface, BAT_RATE)?;
        // let current_percent: BatPercentType = proxy.get(BAT_IFACE.interface, BAT_PERCENT)?;
        // let current_state: BatStateType = proxy.get(BAT_IFACE.interface, BAT_STATE)?;

        // state.set_battery_rate(current_rate);
        // state.set_percent(current_percent);

        matcher! {
            [BAT_IFACE]
            rule: BAT_RATE,
            type: BatRateType,
            call: set_battery_rate,

            rule: BAT_PERCENT,
            type: BatPercentType,
            call: set_percent,

            rule: BAT_STATE,
            type: BatStateType,
            call: set_battery_state,
        }
    }

    let mut loop_count = 0isize;
    loop {
        state.print();
        conn.process(EVENT_TIMEOUT)?;

        loop_count = loop_count.wrapping_add(1);
        eprintln!("[{loop_count}] Processed!");
    }
}

/*
async fn async_main() -> zbus::Result<()> {
    println!("Hello async!");
    Ok(())
}
fn main() -> ! {
    let (sender, receiver) = std::sync::mpsc::channel();
    let main = async { async_main().await.unwrap() };
    let sched = move |runnable| sender.send(runnable).unwrap();
    let (runnable, task) = async_task::spawn_local(main, sched);
    runnable.schedule();
    for runnable in receiver {
        runnable.run();
    }
    unreachable!("This is literally unreachable because the receiver blocks forever")
}
*/

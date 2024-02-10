mod config;
mod state;
mod types;
mod xmlgen;

use futures_util::{TryFutureExt, StreamExt};
use tokio::{
    fs,
    io::{self, AsyncWriteExt},
};

type Res = Result<(), Box<dyn std::error::Error>>;
type Reslt<T> = Result<T, Box<dyn std::error::Error>>;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Res {
    let conn = zbus::Connection::system().await?;
    let upower_proxy = xmlgen::upower::DeviceProxy::new(&conn).await?;

    // let max_brightness = conn
    //     .call_method(
    //         Some("org.freedesktop.login1"),
    //         "/org/freedesktop/login1/session/auto",
    //         Some("org.freedesktop.login1.Session"),
    //         "SetBrightness",
    //         &("backlight", config::BACKLIGHT_PATH, value),
    //     )
    //     .await?;

    let (
        mut percent_stream,
        mut state_stream,
        current_percent,
        current_state,
        should_run_nvidia_smi,
    ) = tokio::join!(
        upower_proxy.receive_percentage_changed(),
        upower_proxy.receive_state_changed(),
        upower_proxy.percentage(),
        upower_proxy.state(),
        types::GfxMode::should_run_nvidia_smi(&conn)
    );

    let mut state = state::State::new(
        conn,
        current_percent?,
        current_state?,
        should_run_nvidia_smi,
    )
    .await;
    state.run_cmd().await?;

    state
        .write(String::from("Starting pmgmt watcher loop"))
        .await?;

    panic!("done");
    loop {
        tokio::select! {
            Some(perc) = percent_stream.next() => {
                match perc.get().await {
                    Ok(p) => state.update_percent(p).await?,
                    Err(e) => state.write(format!("Percent stream error: {e}")).await?,
                }
            }
            Some(stat) = state_stream.next() => {
                match stat.get().await {
                    Ok(s) => state.update_is_plugged(s).await?,
                    Err(e) => state.write(format!("State stream error: {e}")).await?,
                }
            }
        }
    }
}

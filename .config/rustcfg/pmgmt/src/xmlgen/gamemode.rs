//! # D-Bus interface proxy for: `com.feralinteractive.GameMode`
//!
//! This code was generated by `zbus-xmlgen` `5.0.1` from D-Bus introspection data.
//! Source: `Interface '/com/feralinteractive/GameMode' from service 'com.feralinteractive.GameMode' on system bus`.
//!
//! You may prefer to adapt it, instead of using it verbatim.
//!
//! More information can be found in the [Writing a client proxy] section of the zbus
//! documentation.
//!
//! This type implements the [D-Bus standard interfaces], (`org.freedesktop.DBus.*`) for which the
//! following zbus API can be used:
//!
//! * [`zbus::fdo::PeerProxy`]
//! * [`zbus::fdo::IntrospectableProxy`]
//! * [`zbus::fdo::PropertiesProxy`]
//!
//! Consequently `zbus-xmlgen` did not generate code for the above interfaces.
//!
//! [Writing a client proxy]: https://dbus2.github.io/zbus/client.html
//! [D-Bus standard interfaces]: https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces,
use zbus::proxy;
#[proxy(
    interface = "com.feralinteractive.GameMode",
    default_service = "com.feralinteractive.GameMode",
    default_path = "/com/feralinteractive/GameMode",
    gen_blocking = false
)]
pub trait GameMode {
    /// ListGames method
    fn list_games(&self) -> zbus::Result<Vec<(i32, zbus::zvariant::OwnedObjectPath)>>;

    /// QueryStatus method
    fn query_status(&self, arg_1: i32) -> zbus::Result<i32>;

    /// QueryStatusByPID method
    #[zbus(name = "QueryStatusByPID")]
    fn query_status_by_pid(&self, arg_1: i32, arg_2: i32) -> zbus::Result<i32>;

    /// QueryStatusByPIDFd method
    #[zbus(name = "QueryStatusByPIDFd")]
    fn query_status_by_pidfd(
        &self,
        arg_1: zbus::zvariant::Fd<'_>,
        arg_2: zbus::zvariant::Fd<'_>,
    ) -> zbus::Result<i32>;

    /// RefreshConfig method
    fn refresh_config(&self) -> zbus::Result<i32>;

    /// RegisterGame method
    fn register_game(&self, arg_1: i32) -> zbus::Result<i32>;

    /// RegisterGameByPID method
    #[zbus(name = "RegisterGameByPID")]
    fn register_game_by_pid(&self, arg_1: i32, arg_2: i32) -> zbus::Result<i32>;

    /// RegisterGameByPIDFd method
    #[zbus(name = "RegisterGameByPIDFd")]
    fn register_game_by_pidfd(
        &self,
        arg_1: zbus::zvariant::Fd<'_>,
        arg_2: zbus::zvariant::Fd<'_>,
    ) -> zbus::Result<i32>;

    /// UnregisterGame method
    fn unregister_game(&self, arg_1: i32) -> zbus::Result<i32>;

    /// UnregisterGameByPID method
    #[zbus(name = "UnregisterGameByPID")]
    fn unregister_game_by_pid(&self, arg_1: i32, arg_2: i32) -> zbus::Result<i32>;

    /// UnregisterGameByPIDFd method
    #[zbus(name = "UnregisterGameByPIDFd")]
    fn unregister_game_by_pidfd(
        &self,
        arg_1: zbus::zvariant::Fd<'_>,
        arg_2: zbus::zvariant::Fd<'_>,
    ) -> zbus::Result<i32>;

    /// GameRegistered signal
    #[zbus(signal)]
    fn game_registered(
        &self,
        arg_1: i32,
        arg_2: zbus::zvariant::ObjectPath<'_>,
    ) -> zbus::Result<()>;

    /// GameUnregistered signal
    #[zbus(signal)]
    fn game_unregistered(
        &self,
        arg_1: i32,
        arg_2: zbus::zvariant::ObjectPath<'_>,
    ) -> zbus::Result<()>;

    /// ClientCount property
    #[zbus(property)]
    fn client_count(&self) -> zbus::Result<i32>;
}

//! # DBus interface proxy for: `net.hadess.PowerProfiles`
//!
//! This code was generated by `zbus-xmlgen` `3.1.1` from DBus introspection data.
//! Source: `Interface '/net/hadess/PowerProfiles' from service 'net.hadess.PowerProfiles' on system bus`.
//!
//! You may prefer to adapt it, instead of using it verbatim.
//!
//! More information can be found in the
//! [Writing a client proxy](https://dbus.pages.freedesktop.org/zbus/client.html)
//! section of the zbus documentation.
//!
//! This DBus object implements
//! [standard DBus interfaces](https://dbus.freedesktop.org/doc/dbus-specification.html),
//! (`org.freedesktop.DBus.*`) for which the following zbus proxies can be used:
//!
//! * [`zbus::fdo::PropertiesProxy`]
//! * [`zbus::fdo::IntrospectableProxy`]
//! * [`zbus::fdo::PeerProxy`]
//!
//! …consequently `zbus-xmlgen` did not generate code for the above interfaces.

use zbus::dbus_proxy;

#[dbus_proxy(
    interface = "net.hadess.PowerProfiles",
    default_service = "net.hadess.PowerProfiles",
    default_path = "/net/hadess/PowerProfiles"
)]
trait PowerProfiles {
    /// HoldProfile method
    fn hold_profile(&self, profile: &str, reason: &str, application_id: &str) -> zbus::Result<u32>;

    /// ReleaseProfile method
    fn release_profile(&self, cookie: u32) -> zbus::Result<()>;

    /// ProfileReleased signal
    #[dbus_proxy(signal)]
    fn profile_released(&self, cookie: u32) -> zbus::Result<()>;

    /// Actions property
    #[dbus_proxy(property)]
    fn actions(&self) -> zbus::Result<Vec<String>>;

    /// ActiveProfile property
    #[dbus_proxy(property)]
    fn active_profile(
        &self,
    ) -> zbus::Result<crate::modules::power_profiles_daemon::PowerProfileState>;
    fn set_active_profile(&self, value: &str) -> zbus::Result<()>;

    /// ActiveProfileHolds property
    #[dbus_proxy(property)]
    fn active_profile_holds(
        &self,
    ) -> zbus::Result<Vec<std::collections::HashMap<String, zbus::zvariant::OwnedValue>>>;

    /// PerformanceDegraded property
    #[dbus_proxy(property)]
    fn performance_degraded(&self) -> zbus::Result<String>;

    /// PerformanceInhibited property
    #[dbus_proxy(property)]
    fn performance_inhibited(&self) -> zbus::Result<String>;

    /// Profiles property
    #[dbus_proxy(property)]
    fn profiles(
        &self,
    ) -> zbus::Result<Vec<std::collections::HashMap<String, zbus::zvariant::OwnedValue>>>;
}
#![allow(clippy::type_complexity)]
//! # DBus interface proxy for: `org.supergfxctl.Daemon`
//!
//! This code was generated by `zbus-xmlgen` `3.1.1` from DBus introspection data.
//! Source: `Interface '/org/supergfxctl/Gfx' from service 'org.supergfxctl.Daemon' on system bus`.
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
//! * [`zbus::fdo::PeerProxy`]
//! * [`zbus::fdo::IntrospectableProxy`]
//! * [`zbus::fdo::PropertiesProxy`]
//!
//! …consequently `zbus-xmlgen` did not generate code for the above interfaces.

use crate::gfx::{GfxMode, GfxPower};
use zbus::dbus_proxy;

#[dbus_proxy(
    interface = "org.supergfxctl.Daemon",
    default_service = "org.supergfxctl.Daemon",
    default_path = "/org/supergfxctl/Gfx"
)]
// #[dbus_proxy(
//     interface = "org.supergfxctl.Daemon",
//     default_path = "/org/supergfxctl/Gfx"
// )]

trait Daemon {
    /// Config method
    fn config(&self) -> zbus::Result<(u32, bool, bool, bool, bool, u64, u32)>;

    /// Mode method
    // fn mode(&self) -> zbus::Result<u32>;
    fn mode(&self) -> zbus::Result<GfxMode>;

    /// PendingMode method
    // fn pending_mode(&self) -> zbus::Result<u32>;
    fn pending_mode(&self) -> zbus::Result<GfxMode>;

    /// PendingUserAction method
    fn pending_user_action(&self) -> zbus::Result<u32>;

    /// Power method
    // fn power(&self) -> zbus::Result<u32>;
    fn power(&self) -> zbus::Result<GfxPower>;

    /// SetConfig method
    fn set_config(&self, config: &(u32, bool, bool, bool, bool, u64, u32)) -> zbus::Result<()>;

    /// SetMode method
    fn set_mode(&self, mode: u32) -> zbus::Result<u32>;

    /// Supported method
    // fn supported(&self) -> zbus::Result<Vec<u32>>;
    fn supported(&self) -> zbus::Result<Vec<GfxMode>>;

    /// Vendor method
    fn vendor(&self) -> zbus::Result<String>;

    /// Version method
    fn version(&self) -> zbus::Result<String>;

    /// NotifyAction signal
    #[dbus_proxy(signal)]
    fn notify_action(&self, action: u32) -> zbus::Result<()>;

    /// NotifyGfx signal
    #[dbus_proxy(signal)]
    fn notify_gfx(&self, vendor: u32) -> zbus::Result<()>;

    /// NotifyGfxStatus signal
    #[dbus_proxy(signal)]
    fn notify_gfx_status(&self, status: u32) -> zbus::Result<()>;
}

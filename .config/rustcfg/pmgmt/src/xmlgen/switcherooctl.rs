//! # D-Bus interface proxy for: `net.hadess.SwitcherooControl`
//!
//! This code was generated by `zbus-xmlgen` `5.0.1` from D-Bus introspection data.
//! Source: `Interface '/net/hadess/SwitcherooControl' from service 'net.hadess.SwitcherooControl' on system bus`.
//!
//! You may prefer to adapt it, instead of using it verbatim.
//!
//! More information can be found in the [Writing a client proxy] section of the zbus
//! documentation.
//!
//! This type implements the [D-Bus standard interfaces], (`org.freedesktop.DBus.*`) for which the
//! following zbus API can be used:
//!
//! * [`zbus::fdo::PropertiesProxy`]
//! * [`zbus::fdo::IntrospectableProxy`]
//! * [`zbus::fdo::PeerProxy`]
//!
//! Consequently `zbus-xmlgen` did not generate code for the above interfaces.
//!
//! [Writing a client proxy]: https://dbus2.github.io/zbus/client.html
//! [D-Bus standard interfaces]: https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces,
use zbus::proxy;
#[proxy(
    interface = "net.hadess.SwitcherooControl",
    default_service = "net.hadess.SwitcherooControl",
    default_path = "/net/hadess/SwitcherooControl",
    gen_blocking = false
)]
pub trait SwitcherooControl {
    /// GPUs property
    #[zbus(property, name = "GPUs")]
    fn gpus(
        &self,
    ) -> zbus::Result<Vec<std::collections::HashMap<String, zbus::zvariant::OwnedValue>>>;

    /// HasDualGpu property
    #[zbus(property)]
    fn has_dual_gpu(&self) -> zbus::Result<bool>;

    /// NumGPUs property
    #[zbus(property, name = "NumGPUs")]
    fn num_gpus(&self) -> zbus::Result<u32>;
}
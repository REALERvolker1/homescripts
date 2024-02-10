use serde::{Deserialize, Serialize};

/// https://gitlab.com/asus-linux/supergfxctl/-/blob/main/src/pci_device.rs?ref_type=heads
#[derive(
    Debug, Default, zbus::zvariant::Type, PartialEq, Eq, Copy, Clone, Serialize, Deserialize,
)]
pub enum GfxMode {
    Hybrid,
    Integrated,
    /// This mode is for folks using `nomodeset=0` on certain hardware. It allows hot unloading of nvidia
    NvidiaNoModeset,
    Vfio,
    /// The ASUS EGPU is in use
    AsusEgpu,
    /// The ASUS GPU MUX is set to dGPU mode
    AsusMuxDgpu,
    #[default]
    None,
}
impl GfxMode {
    /// connect to supergfxd just to ask if it is hybrid mode, if so then run nvidia-smi in a loop on AC
    pub async fn should_run_nvidia_smi(conn: &zbus::Connection) -> bool {
        if let Ok(m) = conn
            .call_method(
                Some("org.supergfxctl.Daemon"),
                "/org/supergfxctl/Gfx",
                Some("org.supergfxctl.Daemon"),
                "Mode",
                &(),
            )
            .await
        {
            match m.body() {
                Ok(Self::Hybrid) => true,
                _ => false,
            }
        } else {
            false
        }
    }
}

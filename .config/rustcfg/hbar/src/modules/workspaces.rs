use super::*;

#[derive(Debug, Default, Clone, derive_more::Display, PartialEq, Serialize, Deserialize)]
#[display(fmt = "{}{}", "if self.is_active {\"➤ \"} else {\"\"}", name)]
pub struct Workspace {
    pub name: String,
    pub id: isize,
    pub is_active: bool,
}

#[derive(Debug, Default, Clone, PartialEq, Serialize, Deserialize)]
pub struct WorkspaceData {
    pub workspaces: Vec<Workspace>,
}
impl fmt::Display for WorkspaceData {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "[ {} ]",
            self.workspaces
                .iter()
                .map(|w| w.to_string())
                .collect_vec()
                .join(", ")
        )
    }
}

/// The type I have decided to use for monitor IDs
pub type MonitorIdType = u8;

/// The internal representation of a monitor
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Monitor {
    /// The monitor name, like `eDP-1`
    pub name: String,
    /// The internal monitor ID, for faster comparison
    pub id: MonitorIdType,
}
impl Monitor {
    pub fn detect() -> ModResult<HashMap<MonitorIdType, Self>> {
        Ok(HashMap::new())
    }
}

// TODO: Complain about lack of documentation about wayland_protocols
// #[tracing::instrument(skip_all, level = "debug")]
// #[tracing::instrument(skip_all, level = "debug")]
// fn b() {
//     // let e = wayland_protocols_wlr::output_management::v1::client::zwlr_output_configuration_v1::ZwlrOutputConfigurationV1::
//     let e = wayland_protocols::ext::foreign_toplevel_list::v1::client::ext_foreign_toplevel_list_v1::Event::
// }
// pub struct WorkspaceModule;
// impl Module for WorkspaceModule {
//     type StartupData = ;
// }

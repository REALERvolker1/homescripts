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
// TODO: Complain about lack of documentation about wayland_protocols
// #[tracing::instrument(skip(data))]
// #[tracing::instrument(skip(self, sender))]
// fn b() {
//     // let e = wayland_protocols_wlr::output_management::v1::client::zwlr_output_configuration_v1::ZwlrOutputConfigurationV1::
//     let e = wayland_protocols::ext::foreign_toplevel_list::v1::client::ext_foreign_toplevel_list_v1::Event::
// }

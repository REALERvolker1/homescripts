use crate::*;

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

use crate::entry::Entry;

pub fn get_nvidia() -> Entry {
    let version = std::fs::read_to_string("/sys/module/nvidia/version")
        .unwrap_or_else(|_| "Undefined".to_owned());

    Entry::new("Nvidia", version.trim().to_owned())
}

use {
    crate::{entry::EntryMetadata, io::read_append_arrayvec_with_fallback},
    ::arrayvec::ArrayVec,
    ::core::ffi::CStr,
};

pub const MODPATH: &CStr = c"/sys/module/nvidia/version";

/// Append nvidia driver version info to an arrayvec
pub fn append_nvidia<const N: usize>(buf: &mut ArrayVec<u8, N>) -> bool {
    read_append_arrayvec_with_fallback(MODPATH, buf, b"Unknown")
}

pub const METADATA: EntryMetadata = EntryMetadata {
    color: 92,
    name: "nvidia",
    icon: '󰾲',
};

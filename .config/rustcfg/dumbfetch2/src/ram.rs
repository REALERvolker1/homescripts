use {
    ::core::mem::MaybeUninit,
    ::libc::{statfs, sysinfo, utsname},
};

pub(crate) union RandomAssMemory {
    pub sysinfo: SysInfoPacked,
    pub utsname: MaybeUninit<utsname>,
    pub statfs: MaybeUninit<statfs>,
}
impl RandomAssMemory {}
impl Default for RandomAssMemory {
    fn default() -> Self {
        Self {
            sysinfo: SysInfoPacked::uninit(),
        }
    }
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct SysInfoPacked {
    pub info: MaybeUninit<sysinfo>,
    pub buf: itoa::Buffer,
}
impl SysInfoPacked {
    pub fn uninit() -> Self {
        Self {
            info: MaybeUninit::uninit(),
            buf: itoa::Buffer::new(),
        }
    }
}

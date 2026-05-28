use {
    crate::{io::ArrayVecExt, syscall::uname},
    ::arrayvec::ArrayVec,
    ::core::{ffi::CStr, mem::MaybeUninit, num::NonZero},
};

pub fn try_append_kernel<const N: usize>(
    buf: &mut ArrayVec<u8, N>,
    ubuf: &mut MaybeUninit<libc::utsname>,
) -> Option<NonZero<usize>> {
    let name = uname(ubuf).ok()?;

    // SAFETY: This memory is owned by us, and initialized by the OS
    let rel = unsafe { CStr::from_ptr(name.release.as_ptr()) };

    let res = buf.extend_some_from_slice(rel.to_bytes());

    NonZero::new(res)
}

use {
    crate::{syscall::getenv, io::ArrayVecExt},
    ::arrayvec::ArrayVec,
    ::core::num::NonZero,
};

pub fn append_term<const N: usize>(buf: &mut ArrayVec<u8, N>) -> Option<NonZero<usize>> {
    NonZero::new(buf.extend_some_from_slice(getenv(c"TERM")?.to_bytes()))
}

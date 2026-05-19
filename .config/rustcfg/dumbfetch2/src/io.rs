use {
    ::core::{ffi::c_int, num::NonZero},
    ::libc::{STDERR_FILENO, STDOUT_FILENO, write},
};

pub trait LibcWrite {
    fn fd(&self) -> c_int;
    #[inline]
    fn write(&mut self, s: &[u8]) -> Result<usize, NonZero<c_int>> {
        let n = fd_puts_unlocked(self.fd(), s);

        if n < 0 {
            // SAFETY: We know it is NOT zero
            let nzn = unsafe { NonZero::new_unchecked(n as _) };
            Err(nzn)
        } else {
            Ok(n.cast_unsigned())
        }
    }
    #[inline]
    fn multi_write(&mut self, v: &[&[u8]]) -> Result<usize, NonZero<c_int>> {
        v.iter()
            .try_fold(0, |accum, s| self.write(s).map(|r| r.wrapping_add(accum)))
    }
    #[inline(always)]
    fn flush(&mut self) {}
}

pub struct Stdout;
impl LibcWrite for Stdout {
    fn fd(&self) -> c_int {
        STDOUT_FILENO
    }
}
pub struct Stderr;
impl LibcWrite for Stderr {
    fn fd(&self) -> c_int {
        STDERR_FILENO
    }
}
#[inline(always)]
fn fd_puts_unlocked(fd: c_int, s: &[u8]) -> isize {
    unsafe { write(fd, s.as_ptr().cast(), s.len()) }
}

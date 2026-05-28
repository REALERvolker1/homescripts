use {
    ::arrayvec::ArrayVec,
    ::core::{
        ffi::{CStr, c_int},
        mem::MaybeUninit,
        num::NonZero,
    },
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

/// Attempt to read into a provided buffer.
///
/// ## Returns
/// - the guaranteed-initialized part of the buffer if successful.
/// - The old slice if an error occurred (check [`errno`](libc::__errno_location)!)
#[inline]
pub fn read_into_buffer<'b>(
    path: &CStr,
    buf: &'b mut [MaybeUninit<u8>],
) -> Result<&'b mut [u8], &'b mut [MaybeUninit<u8>]> {
    if buf.is_empty() {
        return Err(buf);
    }

    // SAFETY: `CStr` is always a valid reference
    let fd = unsafe { libc::open(path.as_ptr(), libc::O_RDONLY) };

    // SAFETY: We upheld all invariants with the type system, and the OS will cause
    // this to fail if the fd was invalid
    let res: isize = unsafe { libc::read(fd, buf.as_mut_ptr() as _, buf.len()) };

    if res > -1 && fd > -1 {
        // SAFETY: We own this FD, we got the FD from `open`, and we checked for validity.
        unsafe { libc::close(fd) };
        // We don't care about this return value, and we don't care about errno if
        // the read succeeded
    } else {
        return Err(buf);
    }

    let len = res as usize;

    // SAFETY: `libc::read` guarantees this range will be initialized
    Ok(unsafe { buf[..len].assume_init_mut() })
}

const SWAWS: [(); size_of::<usize>()] = [(); size_of::<Result<NonZero<usize>, ()>>()];

/// Returns the new length of `buf`, along with whether the `read` call was successful
#[must_use]
pub fn read_into_buffer_with_fallback<'b>(
    path: &CStr,
    buf: &'b mut [MaybeUninit<u8>],
    fallback: &[u8],
) -> (&'b [u8], bool) {
    match read_into_buffer(path, buf) {
        Ok(r) => (r, true),
        Err(buf) => {
            let fblen = buf.len().min(fallback.len());

            buf[..fblen].write_copy_of_slice(&fallback[..fblen]);

            // SAFETY: We copied initialized data into this range
            (unsafe { buf[..fblen].assume_init_mut() }, false)
        }
    }
}

pub fn read_append_arrayvec_with_fallback<const N: usize>(
    path: &CStr,
    buf: &mut ArrayVec<u8, N>,
    fallback: &[u8],
) -> bool {
    let blen = buf.len();
    let len = buf.remaining_capacity();

    // SAFETY: If this wraps around, we have bigger problems to worry about
    let data: *mut u8 = unsafe { buf.as_mut_ptr().add(blen) };
    // The inner storage of `ArrayVec` is an array of `MaybeUninit<T>`
    let data: *mut MaybeUninit<u8> = data.cast();

    let (appslice, read_succ) = read_into_buffer_with_fallback(
        path,
        unsafe { core::slice::from_raw_parts_mut(data, len) },
        fallback,
    );

    let length = blen + appslice.len();
    debug_assert!(length <= buf.capacity());

    // SAFETY: We size-checked this, and the parent function guarantees this data
    // is valid
    unsafe { buf.set_len(length) };

    read_succ
}

pub trait ArrayVecExt<T> {
    fn extend_some_from_slice(&mut self, s: &[T]) -> usize;
}
impl<T: Copy, const N: usize> ArrayVecExt<T> for ArrayVec<T, N> {
    fn extend_some_from_slice(&mut self, s: &[T]) -> usize {
        let smin = s.len().min(self.remaining_capacity());

        self.try_extend_from_slice(&s[..smin]).unwrap();

        smin
    }
}

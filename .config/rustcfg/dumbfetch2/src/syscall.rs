use ::core::{
    ffi::{CStr, c_int},
    mem::MaybeUninit,
};

/// Calls [`getenv`](libc::getenv) internally.
/// The resulting string is a pointer to the value in the environment table.
///
/// For more information, read the manpage: `getenv(3)`
///
/// # Safety
/// Reads a static variable that can be mutated via unsafe code.
/// It takes unsafe code to make this unsafe.
pub fn getenv(key: &CStr) -> Option<&CStr> {
    // SAFETY: `key` itself is nonnull, and ends with NUL
    let envp = unsafe { libc::getenv(key.as_ptr()) };
    if envp.is_null() {
        return None;
    }
    // SAFETY: The platform's CRT *MUST* return a nonnull C-string if there is a valid match
    let r = unsafe { CStr::from_ptr(envp) };
    Some(r)
}
/// Calls [`getenv`](libc::getenv) internally.
/// Returns `true` if the environment variable is set and non-empty.
///
/// For more information, read the manpage: `getenv(3)`
///
/// # Safety
/// Reads a static variable that can be mutated via unsafe code.
/// It takes unsafe code to make this unsafe.
pub fn hasenv(key: &CStr) -> bool {
    // SAFETY: `key` itself is nonnull, and ends with NUL
    let envp = unsafe { libc::getenv(key.as_ptr()) };
    if envp.is_null() {
        return false;
    }
    // SAFETY: The platform's CRT *MUST* return a nonnull C-string if there is a valid match
    let firstchr = unsafe { *envp };

    firstchr != 0
}

/// # Safety
/// Caller asserts the provided function will initialize `ubuf`
unsafe fn try_syscall_noarg<T>(
    ubuf: &mut MaybeUninit<T>,
    f: unsafe extern "C" fn(*mut T) -> c_int,
) -> Result<&mut T, &mut MaybeUninit<T>> {
    // SAFETY: guaranteed by the type system and the caller
    let res = unsafe { f(ubuf.as_mut_ptr()) };

    if res < 0 {
        Err(ubuf)
    } else {
        // SAFETY: Caller asserts the function initializes the buffer
        Ok(unsafe { ubuf.assume_init_mut() })
    }
}
/// # Safety
/// Caller asserts the provided function will initialize `ubuf`
#[inline]
unsafe fn try_syscall_closure<T>(
    ubuf: &mut MaybeUninit<T>,
    f: impl FnOnce(*mut T) -> c_int,
) -> Result<&mut T, &mut MaybeUninit<T>> {
    // SAFETY: guaranteed by the type system
    let res = f(ubuf.as_mut_ptr());

    if res < 0 {
        Err(ubuf)
    } else {
        // SAFETY: Caller asserts the function initializes the buffer
        Ok(unsafe { ubuf.assume_init_mut() })
    }
}

#[inline]
pub fn statfs<'b>(
    path: &CStr,
    ubuf: &'b mut MaybeUninit<libc::statfs>,
) -> Result<&'b mut libc::statfs, &'b mut MaybeUninit<libc::statfs>> {
    unsafe { try_syscall_closure(ubuf, |p| libc::statfs(path.as_ptr(), p)) }
}

#[inline]
pub fn uname(
    ubuf: &mut MaybeUninit<libc::utsname>,
) -> Result<&mut libc::utsname, &mut MaybeUninit<libc::utsname>> {
    unsafe { try_syscall_noarg(ubuf, libc::uname) }
}

#[inline]
pub fn sysinfo(
    ubuf: &mut MaybeUninit<libc::sysinfo>,
) -> Result<&mut libc::sysinfo, &mut MaybeUninit<libc::sysinfo>> {
    unsafe { try_syscall_noarg(ubuf, libc::sysinfo) }
}

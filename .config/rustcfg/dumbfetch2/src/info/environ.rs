use ::core::ffi::CStr;

const X_ENV_DETECT: &CStr = c"DISPLAY";
const WAYLAND_ENV_DETECT: &CStr = c"WAYLAND_DISPLAY";
const DESKTOP_ENV_DETECT: &CStr = c"XDG_CURRENT_DESKTOP";

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

pub fn detect_desktop_runtime() -> char {
    if hasenv(WAYLAND_ENV_DETECT) {
        ''
    } else if hasenv(X_ENV_DETECT) {
        ''
    } else {
        ''
    }
}

pub const fn env_name_to_nerdfont_icon(env_name_lowercase: &[u8]) -> Option<char> {
    let c = match env_name_lowercase {
        b"i3" => '',
        b"hyprland" => '',
        b"sway" => '',
        b"bspwm" => '',
        b"dwm" => '',
        b"qtile" => '',
        b"lxqt" => '',
        b"mate" => '',
        b"deepin" => '',
        b"pantheon" => '',
        b"enlightenment" => '',
        b"fluxbox" => '',
        b"xfce" => '',
        b"kde" => '',
        b"plasma" => '',
        b"cinnamon" => '',
        b"gnome" => '',
        _ => return None,
    };
    Some(c)
}

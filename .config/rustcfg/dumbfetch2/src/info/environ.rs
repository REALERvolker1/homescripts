use {
    crate::{entry::EntryMetadata, io::ArrayVecExt, syscall::getenv},
    ::arrayvec::ArrayVec,
    ::core::ffi::CStr,
};

const X_ENV_DETECT: &CStr = c"DISPLAY";
const WAYLAND_ENV_DETECT: &CStr = c"WAYLAND_DISPLAY";
const DESKTOP_ENV_DETECT: &CStr = c"XDG_CURRENT_DESKTOP";

const ENV_NAME_BUF_LEN: usize = 16;

fn desktop_detection<const N: usize>(
    buf: &mut Option<&mut ArrayVec<u8, N>>,
) -> Option<(Option<char>, usize)> {
    let e = getenv(DESKTOP_ENV_DETECT)?;

    if e.is_empty() {
        return None;
    }

    let ebytes = e.to_bytes();

    let res = buf
        .as_mut()
        .map(|b| b.extend_some_from_slice(ebytes))
        .unwrap_or_default();

    if ebytes.len() > ENV_NAME_BUF_LEN {
        return Some((None, res));
    }

    let mut env_name_buf = [0; ENV_NAME_BUF_LEN];

    let env_name_slice = &mut env_name_buf[..ebytes.len()];
    // strcpy so that we don't mutate the variable
    env_name_slice.copy_from_slice(ebytes);
    env_name_slice
        .iter_mut()
        .for_each(|b| *b = b.to_ascii_lowercase());

    // close this off so we don't mutate the inner vector again
    *buf = None;

    Some((env_name_to_nerdfont_icon(env_name_slice), res))
}

pub fn detect_desktop_runtime<const N: usize>(
    mut buf: Option<&mut ArrayVec<u8, N>>,
) -> (EntryMetadata, usize) {
    let mut nwritten = 0;
    let mut meta = EntryMetadata {
        name: "Desk",
        icon: '',
        color: 96,
    };

    if let Some((icon, app)) = desktop_detection(&mut buf) {
        if let Some(icon) = icon {
            meta.icon = icon;
            return (meta, app);
        } else {
            nwritten = app;
        }
    }

    if let Some(e) = getenv(WAYLAND_ENV_DETECT) {
        if let Some(buf) = buf {
            nwritten = buf.extend_some_from_slice(e.to_bytes());
        }
        meta.icon = '';
    } else if let Some(e) = getenv(X_ENV_DETECT) {
        if let Some(buf) = buf {
            nwritten = buf.extend_some_from_slice(e.to_bytes());
        }
        meta.icon = '';
    }

    (meta, nwritten)
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

use phf_macros::phf_map;
use std::env;

use crate::entry::Entry;

static DESKTOP_ICONS: phf::Map<&'static str, char> = phf_map! {
    "i3" => '',
    "hyprland" => '',
    "sway" => '',
    "bspwm" => '',
    "dwm" => '',
    "qtile" => '',
    "lxqt" => '',
    "mate" => '',
    "deepin" => '',
    "pantheon" => '',
    "enlightenment" => '',
    "fluxbox" => '',
    "xfce" => '',
    "kde" => '',
    "plasma" => '',
    "cinnamon" => '',
    "gnome" => '',
};

macro_rules! default_icon {
    () => {
        if env::var_os("WAYLAND_DISPLAY").is_some() {
            ''
        } else if env::var_os("DISPLAY").is_some() {
            ''
        } else {
            ''
        }
    };
}

pub fn get_xdg_desktop() -> Entry {
    let (icon, content) = match env::var("XDG_CURRENT_DESKTOP") {
        Ok(d) => {
            let lowercase = d.to_ascii_lowercase();
            (
                match DESKTOP_ICONS.get(&lowercase) {
                    Some(i) => *i,
                    None => default_icon!(),
                },
                d,
            )
        }
        Err(_) => (default_icon!(), "Undefined".to_owned()),
    };

    Entry::new_providing_icon("Desk", icon, content)
}

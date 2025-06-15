use {
    ::ahash::{HashMap, HashMapExt},
    ::std::path::PathBuf,
};

pub const SUFFIX_LS_COLORS_ENV: &str = "LS_COLORS";
pub const CONFIG_HOME_ENV: &str = "CN_CONFIG_HOME";

thread_local! {
    /// This is here because I want to use my (rather large) LS_COLORS variable to color the names all pretty-like :^)
    pub static SUFFIX_LS_COLORS: HashMap<&'static str, &'static str> = {
        if crate::io_methods::isatty() {
            if let Ok(ls_colors) = std::env::var(SUFFIX_LS_COLORS_ENV) {
                if !ls_colors.is_empty() {
                    return ls_colors
                        .split(':')
                        .filter_map(|s| s.split_once('='))
                        .filter(|(k, _)| k.starts_with('*')) // filter out regular files
                        .map(|(k, v)| (heap_ref(k), heap_ref(v)))
                        .collect();
                }
            }
        }

        HashMap::new()
    };

    // pub static CONFIG_HOME
}

/// Create a static ref to any arbitrary string
#[inline(always)]
pub fn heap_ref(s: impl Into<Box<str>>) -> &'static str {
    Box::leak(s.into())
}

pub fn ls_colors_lookup(extension: &str) -> Option<&'static str> {
    SUFFIX_LS_COLORS.with(|l| l.get(extension).copied())
}

pub fn config_home() -> Option<PathBuf> {
    if let Some(h) = std::env::var_os(CONFIG_HOME_ENV) {
        let h_path = PathBuf::from(h);
        if h_path.is_dir() {
            return Some(h_path);
        }

        return None;
    }

    let mut cfg_dir = match std::env::var_os("XDG_CONFIG_HOME") {
        Some(h) => PathBuf::from(h),
        None => {
            let mut p = PathBuf::from(std::env::var_os("HOME")?);
            p.push(".config");
            p
        }
    };

    cfg_dir.push("cn");

    if cfg_dir.is_dir() {
        return Some(cfg_dir);
    }

    None
}

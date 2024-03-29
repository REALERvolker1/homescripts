use phf_macros::phf_map;
use std::fmt;

macro_rules! keys {
    ($( [$key:expr] $color:expr $(, $icon:expr)? );+$(;)?) => {
        const MAX_LEN: usize = max_key_len(&[$( $key ),+]);
        static KEYWORD_SPACES: phf::Map<&'static str, &'static str> = phf_map! {
            $( $key => ::const_format::str_repeat!(" ", 2 + (MAX_LEN - $key.len())) ),+
        };
        static KEYWORD_COLOR: phf::Map<&'static str, &'static str> = phf_map! {
            $( $key => ::const_format::formatcp!("\x1b[0;9{}m", $color) ),+
        };
        static KEYWORD_ICON: phf::Map<&'static str, char> = phf_map! {
            $( $( $key => $icon, )? )+
        };
    };
}

keys! {
    ["Uptime"]
    5u8, '󰅐';
    ["Term"]
    4u8, '';
    ["Disk"]
    3u8, '󰋊';
    ["Nvidia"]
    2u8, '󰾲';
    ["Kernel"]
    1u8, '';
    ["Desk"]
    6u8;
}

const fn max_key_len(keys: &[&str]) -> usize {
    let mut max = 0;
    konst::iter::for_each! {key in keys =>
        if key.len() > max { max = key.len(); }
    };
    max
}

#[derive(Debug, PartialEq, Eq)]
pub struct Entry {
    pub key: &'static str,
    pub spaces: &'static str,
    pub color: &'static str,
    pub icon: char,
    pub content: String,
}
impl Entry {
    // pub fn assured_new(key: &'static str, content: D) -> Self {}
    #[inline(always)]
    pub fn new(key: &'static str, content: String) -> Self {
        Self::new_opt(key, None, None, None, content).unwrap()
    }
    #[inline(always)]
    pub fn new_providing_icon(key: &'static str, icon: char, content: String) -> Self {
        Self::new_opt(key, None, None, Some(icon), content).unwrap()
    }

    /// You want to provide some, but not all info
    pub fn new_opt(
        key: &'static str,
        spaces: Option<&'static str>,
        color: Option<&'static str>,
        icon: Option<char>,
        content: String,
    ) -> Option<Self> {
        let spaces = match spaces {
            Some(s) => s,
            None => KEYWORD_SPACES.get(key)?,
        };

        let icon = match icon {
            Some(i) => i,
            None => *KEYWORD_ICON.get(key)?,
        };

        let color = match color {
            Some(c) => c,
            None => KEYWORD_COLOR.get(key)?,
        };

        Some(Self {
            key,
            spaces,
            color,
            icon,
            content,
        })
    }
    pub fn length_please_keep_synced_with_display(&self) -> usize {
        // space + icon + space + key + colon + pad spaces + content + space
        1 + 1
            + 1
            + self.key.chars().count()
            + 1
            + self.spaces.len()
            + self.content.chars().count()
            + 1
    }
}
impl fmt::Display for Entry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{} {} {}:{}\x1b[1m{} ",
            self.color, self.icon, self.key, self.spaces, self.content
        )
    }
}

#[macro_export]
macro_rules! undef {
    ($key:expr) => {
        Entry::new_opt($key, None, None, None, "Undefined".to_owned())
    };
    (@opt $expression:expr, $key:expr) => {
        match $expression {
            Some(v) => v,
            None => return $crate::undef!($key).unwrap(),
        }
    };
    (@err $expression:expr, $key:expr) => {
        match $expression {
            Ok(v) => v,
            Err(_) => return $crate::undef!($key).unwrap(),
        }
    };
}

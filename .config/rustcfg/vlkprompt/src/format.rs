use crate::{config, configlib};

/// The type I want to have icons in for whatever reason
pub type Icon = &'static str;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Color {
    /// A color from 0 to 255, formatted as `\e[x8;5;<color>m`,
    /// "x" being 3 or 4 to denote foreground or background.
    Color(u8),
    /// A raw ANSI string, like `"\e[0;48;5;38;5;45m"`.
    /// This is just here for customizability, I would not recommend actually using it,
    RawAnsi(&'static str),
    /// an ANSI reset sequence `"\e[0m"`
    Reset,
    /// no ansi color, basically do nothing
    None,
}
impl Color {
    /// Convert this color to an ANSI string.
    pub fn to_ansi(&self) -> String {
        match self {
            Self::Color(c) => format!("\x1b[38;5;{}m", c),
            Self::RawAnsi(s) => String::from(*s),
            Self::Reset => String::from("\x1b[0m"),
            Self::None => String::new(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Format {
    pub icon: Icon,
    pub text: Color,
    pub color: Color,
}
impl Format {
    pub fn new(icon: Icon, text: Color, color: Color) -> Self {
        Self { icon, text, color }
    }
    /// The format for a powerline separator.
    /// Here, previous means the one to the left, which is considered previous by ansi terminals
    pub fn powerline_separator(separator: Icon, previous: Color, next: Color) -> Self {
        Self {
            icon: separator,
            text: previous,
            color: next,
        }
    }
}

/// The display format for the segment.
///
/// Please note that since zsh runs all this with `print -P`, you must make all the percent signs `%%`.
///
/// If the text is `None`, it will be skipped.
/// If the icon is `false`, it will be skipped.
/// If both are falsey, it will all be skipped entirely.
///
/// To override this behavior, set `override_display` to `true`.
/// The boolean you choose will force it to either display or not.
/// This is useful if you want a zero-width segment, as setting one property to `""` will make it format with padding spaces.
#[derive(Debug, Clone)]
pub struct Segment {
    /// The text to display. If None, the text will be skipped.
    pub text: Option<String>,
    /// The icon to display. If None, the icon will be skipped.
    pub show_icon: bool,
    /// Override display on or off
    pub override_display: bool,
    /// The colors and icons and whatnot
    pub format: Format,
    /// The next segment's formatting, so it can have the cool powerline effect
    pub next_color: Color,
}
impl Segment {
    /// Get the string content of the segment, without the formatting.
    pub fn to_fmt_string(&self) -> Option<String> {
        let mut format_string = String::new();

        let icon;
        let middle_padding;
        let text;

        let has_icon = self.show_icon;
        let has_text;

        if let Some(t) = self.text {
            has_text = true;
            text = t.as_str();
            // have a space between the icon and the text
            middle_padding = if has_icon { " " } else { "" };
        } else {
            has_text = false;
            text = "";
            middle_padding = "";
        }

        let padding_spaces = if has_icon || has_text {
            // I have padding spaces, because the powerline segment looks weird without them. ~/dir vs  ~/dir 
            " "
        } else if self.override_display {
            // neither are specified but we still want this segment anyway!
            ""
        } else {
            // blank segment, goodbye
            return None;
        };

        Some(format!(
            "{}{}{}{}{}",
            padding_spaces, icon, middle_padding, text, padding_spaces,
        ))
    }
}

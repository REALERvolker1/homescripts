#![allow(static_mut_refs)]

use {
    ::core::{
        fmt::{Display, Write},
        marker::PhantomData,
    },
    ::lscolors::{LsColors, Style},
    ::std::{
        ffi::OsStr,
        io::IsTerminal,
        path::{Path, PathBuf},
    },
};

#[macro_export]
macro_rules! choice_string_array {
    ($mod_name:ident: [$( $var:ident = $elem:expr ),+$(,)?]) => {
        pub mod $mod_name {
            $( pub const $var: &'static str = $elem; )+
            pub const SLICE: &'static [&'static str] = &[$( $var ),+];
            pub const SLICE_DISPLAY: &'static str = ::const_format::str_splice_out!(::core::concat!($( ", ", $elem),+), ..2, "");
        }
    };
}

choice_string_array! {
    colorwhen: [
        ALWAYS = "--color",
        AUTO = "--auto-color",
        NEVER = "--no-color",
    ]
}

struct PathFormatter<'a> {
    pub path: &'a Path,
    pub ls_colors: &'a LsColors,
}
impl Display for PathFormatter<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut components = self.ls_colors.style_for_path_components(self.path);
        components.try_for_each(|(component, color)| {
            let component_string = component.to_string_lossy();
            if let Some(color) = color {
                color.to_owo_colors_style().style(component_string).fmt(f)?;
            } else {
                component_string.fmt(f)?;
            }
            Ok(())
        })
    }
}

pub enum ColorContext {
    NoColor,
    Color {
        ls_colors: LsColors,
        default_style: Style,
        link_style: Style,
    },
}
impl ColorContext {
    pub fn autodetect() -> Self {
        if let Some(s) = std::env::var_os("NO_COLOR") {
            if !s.is_empty() {
                return Self::NoColor;
            }
        }

        if std::io::stdout().is_terminal() {
            return Self::new_color();
        }

        Self::NoColor
    }

    pub fn new_color() -> Self {
        let ls_colors = LsColors::from_env().unwrap_or_default();
        let default_style = ::lscolors::Style::default();

        Self::Color {
            link_style: *ls_colors
                .style_for_indicator(::lscolors::Indicator::SymbolicLink)
                .unwrap_or(&default_style),
            ls_colors,
            default_style,
        }
    }
    pub fn fmt_path(&self, path: impl AsRef<Path>) -> String {
        match self {
            Self::NoColor => path.as_ref().display().to_string(),
            Self::Color { ls_colors, .. } => PathFormatter {
                ls_colors,
                path: path.as_ref(),
            }
            .to_string(),
        }
    }
}

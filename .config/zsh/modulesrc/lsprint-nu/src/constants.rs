use lazy_static::lazy_static;
use std::env;
lazy_static! {
    pub static ref LS_COLORS: lscolors::LsColors =
        lscolors::LsColors::from_env().unwrap_or_default();
    pub static ref BOX_DRAWING: BoxDrawingChars = BoxDrawingTheme::new().get_box_drawing_chars();
    pub static ref MAX_ENTRY_WIDTH: usize =
        if let Ok(width_var) = env::var("LSPRINT_MAX_ENTRY_WIDTH") {
            if let Ok(w) = width_var.parse::<usize>() {
                w
            } else {
                30
            }
        } else {
            30
        };
    pub static ref ENTRY_TRUNC: String =
        env::var("LSPRINT_TRUNCATE_STRING").unwrap_or("...".to_owned());
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
pub enum BoxDrawingTheme {
    Rounded,
    Square,
    Ascii,
}
impl Default for BoxDrawingTheme {
    fn default() -> Self {
        let term = env::var("TERM").unwrap_or("linux".to_string());
        if term == "linux" {
            Self::Ascii
        } else {
            Self::Rounded
        }
    }
}
impl BoxDrawingTheme {
    pub fn new() -> Self {
        if let Ok(char_override) = env::var("LSPRINT_BOX_DRAWING_CHARS") {
            match char_override.as_str() {
                "rounded" => Self::Rounded,
                "square" => Self::Square,
                "ascii" => Self::Ascii,
                _ => Self::default(),
            }
        } else {
            Self::default()
        }
    }
    pub fn get_box_drawing_chars(&self) -> BoxDrawingChars {
        match self {
            Self::Rounded => BoxDrawingChars {
                top_left_corner: '╭',
                top_right_corner: '╮',
                bottom_left_corner: '╰',
                bottom_right_corner: '╯',
                vertical: '│',
                horizontal: '─',
                top_intersection: '┬',
                bottom_intersection: '┴',
                left_intersection: '├',
                right_intersection: '┤',
                intersection: '┼',
            },
            Self::Square => BoxDrawingChars {
                top_left_corner: '┌',
                top_right_corner: '┐',
                bottom_left_corner: '└',
                bottom_right_corner: '┘',
                vertical: '│',
                horizontal: '─',
                top_intersection: '┬',
                bottom_intersection: '┴',
                left_intersection: '├',
                right_intersection: '┤',
                intersection: '┼',
            },
            Self::Ascii => BoxDrawingChars {
                top_left_corner: '+',
                top_right_corner: '+',
                bottom_left_corner: '+',
                bottom_right_corner: '+',
                vertical: '|',
                horizontal: '-',
                top_intersection: '+',
                bottom_intersection: '+',
                left_intersection: '+',
                right_intersection: '+',
                intersection: '+',
            },
        }
    }
}

/// A general struct that contains all the box drawing characters I need to make pretty graphs
#[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
pub struct BoxDrawingChars {
    pub top_left_corner: char,
    pub top_right_corner: char,
    pub bottom_left_corner: char,
    pub bottom_right_corner: char,
    pub vertical: char,
    pub horizontal: char,
    pub top_intersection: char,
    pub bottom_intersection: char,
    pub left_intersection: char,
    pub right_intersection: char,
    pub intersection: char,
}
// impl BoxDrawingChars {
//     pub fn new(theme: Option<BoxDrawingTheme>) -> Self {
//         theme.unwrap_or_default().get_box_drawing_chars()
//     }
// }

use std::{
    collections::HashMap,
    path::{Path, PathBuf},
};

use static_init::dynamic;

// use lscolors::Color;
use nu_ansi_term::{self, Color, Style};

/// Helper macro to create styles. Be careful, as editing it does not update the macro in other files
#[macro_export]
macro_rules! style {
    ($color:expr) => {
        Color::Fixed($color).reset_before_style()
    };
    ($color:expr, bold) => {
        Color::Fixed($color).reset_before_style().bold()
    };
}

pub struct ColorConfig {
    pub root_color: Style,
    pub user_color: Style,
    pub other_user_color: Style,
    pub unknown_user_color: Style,
    pub state_zombie_color: Style,
    pub state_running_color: Style,
    pub state_idle_color: Style,
    pub state_sleeping_color: Style,
    pub state_disksleep_color: Style,
    pub state_unknown_color: Style,
    pub args_color: Style,
}
impl Default for ColorConfig {
    fn default() -> Self {
        Self {
            root_color: style!(196, bold),
            user_color: style!(48, bold),
            other_user_color: style!(51),
            unknown_user_color: style!(196),
            state_zombie_color: style!(124, bold),
            state_running_color: style!(46, bold),
            state_idle_color: style!(190),
            state_sleeping_color: style!(184),
            state_disksleep_color: style!(172, bold),
            state_unknown_color: style!(196, bold),
            args_color: style!(34),
        }
    }
}

// lazy_static! {
//     pub static ref COLOR_CONFIG: ColorConfig = ColorConfig::default();
// }
#[dynamic]
pub static COLOR_CONFIG: ColorConfig = ColorConfig::default();

#[test]
fn test_color_macro() {
    let color = style!(240);
    let ansi_color = Color::Fixed(240).reset_before_style();
    assert_eq!(color, ansi_color);
}

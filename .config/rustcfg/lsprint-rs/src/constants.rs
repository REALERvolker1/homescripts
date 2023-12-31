pub const PAD_SPACE: &str = " ";
pub const PAD_SPACES_WIDTH: usize = 1;
/// Literally just here to save a single cpu instruction per loop
pub const PAD_SPACES_DOUBLED: usize = 2 * PAD_SPACES_WIDTH;

pub struct BoxDrawing {
    pub top_left: char,
    pub top_right: char,
    pub bottom_left: char,
    pub bottom_right: char,
    pub vertical: char,
    pub horizontal: char,
    pub horizontal_intersection_left: char,
    pub horizontal_intersection_right: char,
    pub vertical_intersection_top: char,
    pub vertical_intersection_bottom: char,
    pub intersection: char,
}

// pub const BOX_DRAWING = BoxDrawing {
//     top_left: '┌',
//     top_right: '┐',
//     bottom_left: '└',
//     bottom_right: '┘',
//     vertical: '│',
//     horizontal: '─',
// };

/// I like curved more
pub const BOX_DRAWING_CURVED: BoxDrawing = BoxDrawing {
    top_left: '╭',
    top_right: '╮',
    bottom_left: '╰',
    bottom_right: '╯',
    vertical: '│',
    horizontal: '─',
    horizontal_intersection_left: '├',
    horizontal_intersection_right: '┤',
    vertical_intersection_top: '┬',
    vertical_intersection_bottom: '┴',
    intersection: '┼',
};

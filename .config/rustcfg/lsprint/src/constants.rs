/// The maximum height of the output window in terminal rows.
/// Includes box-drawing characters, so really the max ls output is 8.
pub const MAX_OUTPUT_HEIGHT: u16 = 12;

/// This is the percentage of the desired output height in terminal rows.
/// The output should take up 20% of the screen.
pub const OUTPUT_HEIGHT_PERCENTAGE: u16 = 20;

/// This is the minimum size of the output window before it disappears
pub const MIN_WINDOW_HEIGHT_PERCENT: u16 = 6;

/// This is the minimum height of the window.
/// The minimum width is the maximum width of the largest file fmt element + 4
pub const MIN_WINDOW_HEIGHT: u16 = MIN_WINDOW_HEIGHT_PERCENT * 5;

pub struct BoxDrawings {
    pub top_left: char,
    pub top_right: char,
    pub bottom_left: char,
    pub bottom_right: char,
    pub left: char,
    pub right: char,
    pub top: char,
    pub bottom: char,
}

pub const BOX_DRAWINGS: BoxDrawings = BoxDrawings {
    top_left: '╭',
    top_right: '╮',
    bottom_left: '╰',
    bottom_right: '╯',
    left: '│',
    right: '│',
    top: '─',
    bottom: '─',
};

/// The amount of padding on the left and right of the output, to leave room for box drawings
pub const RESERVE_SIDE_PAD: u16 = 4;

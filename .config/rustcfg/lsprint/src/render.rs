use crate::constants;
use crate::constants::*;
use crate::ls;
use comfy_table;
use crossterm;
use lscolors;
use std::fs::DirEntry;
use std::fs::ReadDir;
use std::io;

/// render function to display the stuff on the screen
pub fn render(
    x_max: u16,
    y_max: u16,
    directory: &Vec<DirEntry>,
    ls_colors: &lscolors::LsColors,
) -> io::Result<()> {
    // let file_display = get_fmt_files(
    //     x_max - constants::RESERVE_SIDE_PAD,
    //     y_max,
    //     directory,
    //     ls_colors,
    // );
    // let (x, y) = crossterm::cursor::position()?;

    let file_display = directory
        .iter()
        .filter_map(|f| ls::File::new(&f.path()))
        .map(|f| f.fmt_with_colors(ls_colors))
        .collect::<Vec<String>>();

    println!("{} files", file_display.len());

    let mut table = comfy_table::Table::new();
    table
        .load_preset(comfy_table::presets::UTF8_BORDERS_ONLY)
        .apply_modifier(comfy_table::modifiers::UTF8_ROUND_CORNERS)
        .apply_modifier(comfy_table::modifiers::UTF8_SOLID_INNER_BORDERS)
        .set_content_arrangement(comfy_table::ContentArrangement::DynamicFullWidth)
        .add_row(comfy_table::Row::from(file_display));

    // println!("Files:\n{}", file_display.join("\n"));
    println!("{}", table);

    // println!("Width: {}, Height: {}, x: {}, y: {}", x_max, y_max, x, y);

    Ok(())
}

// /// Get all the files that will fit on the screen, and return a ready-formatted vector for printing
// fn get_fmt_files(
//     desired_width: u16,
//     desired_height: u16,
//     directory: &[DirEntry],
//     ls_colors: &lscolors::LsColors,
// ) -> Vec<String> {
//     let mut file_display = Vec::with_capacity(desired_height as usize);
//     // gets cleared out when it reaches the max width
//     let mut tmp_file_row = Vec::new();
//     // have sizing as mutable ints for performance. Don't re-count every single iterator every single time.
//     // the width of all the file display strings, excluding spacing between them
//     let mut tmp_file_row_width: u16 = 0;
//     // the number of files in the current row
//     let mut tmp_file_row_count: u16 = 0;
//     // the number of iterations
//     let mut count: usize = 0;
//     // the number of lines in the file display
//     let mut file_display_count: u16 = 0;

//     for entry in directory {
//         let entry_file = if let Some(ef) = ls::File::new(&entry.path()) {
//             ef
//         } else {
//             // skip it if unable to get the file info
//             continue;
//         };

//         let len = entry_file.name_fmt_length;
//         if len > u16::MAX as usize {
//             // prevent overflow
//             continue;
//         }
//         let new_width = tmp_file_row_width + len as u16; // adds here
//                                                          // add tmp_file_row_count for the mandatory spaces
//         let padded_width = new_width + tmp_file_row_count; // adds even more here

//         // ready to push the buffer to the row!
//         if padded_width > desired_width {
//             file_display_count += 1;

//             let real_result_string = justify_lines(
//                 desired_width,
//                 tmp_file_row_width,
//                 tmp_file_row_count,
//                 &tmp_file_row,
//             ); // for some reason the difference is oob here???

//             file_display.push(real_result_string);
//             tmp_file_row_width = 0;
//             tmp_file_row.clear();

//             if file_display_count > desired_height {
//                 // we're done here. This should trigger when it is at the desired height
//                 break;
//             }
//         }

//         count += 1;
//         tmp_file_row_count += 1;
//         tmp_file_row_width = new_width;
//         let formatted_entry_file = entry_file.fmt_with_colors(ls_colors);
//         tmp_file_row.push(formatted_entry_file);
//     }
//     if tmp_file_row_width != 0 {
//         file_display.push(justify_lines(
//             desired_width,
//             tmp_file_row_width,
//             tmp_file_row_count,
//             &tmp_file_row,
//         ));
//     }

//     file_display
// }

// fn justify_lines(
//     desired_width: u16,
//     tmp_file_row_width: u16,
//     tmp_file_row_count: u16,
//     tmp_file_row: &Vec<String>,
// ) -> String {
//     let width_diff = desired_width - tmp_file_row_width;
//     let is_content_even = tmp_file_row_width % 2 == 0;
//     let is_diff_even = width_diff % 2 == 0;

//     let padding = ((width_diff / 2) / (tmp_file_row_count + 1)) as usize;
//     // let pad_string = " ".repeat(padding as usize);

//     // let mut result_string = String::new();
//     let result_string = tmp_file_row
//         .iter()
//         .map(|f| format!("{:^padding$}", &f))
//         .collect::<Vec<String>>()
//         .join("");

//     let real_result_string =
//         if (is_content_even && !is_diff_even) || (!is_content_even && is_diff_even) {
//             // one is different from the other
//             format!("{} ", &result_string)
//         } else {
//             result_string
//         };

//     real_result_string
// }

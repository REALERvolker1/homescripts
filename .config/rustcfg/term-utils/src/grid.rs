use std::fmt::Debug;

use crate::*;
use term_grid;

#[derive(Debug, Clone)]
pub struct GridItem {
    pub string: String,
    pub length: usize,
}
impl From<&str> for GridItem {
    fn from(s: &str) -> Self {
        Self {
            string: s.to_string(),
            length: unicode_width::UnicodeWidthStr::width(s),
        }
    }
}

pub fn print_grid<I>(contents: I, width: usize) -> Option<String>
where
    I: Iterator<Item = GridItem>,
{
    let mut grid = term_grid::Grid::new(term_grid::GridOptions {
        direction: term_grid::Direction::LeftToRight,
        filling: term_grid::Filling::Text(" | ".to_owned()),
    });

    contents.for_each(|e| {
        grid.add(term_grid::Cell {
            contents: e.string,
            width: e.length,
        })
    });
    if let Some(s) = grid.fit_into_width(width) {
        Some(format!("{}", s))
    } else {
        None
    }
}

/// The function to print a directory with ls_colors in a grid
pub fn ls_grid(
    term_props: &utils::TermProps,
    directory: &Path,
    ls_colors: &lscolors::LsColors,
) -> Result<String, error::TuError> {
    let directory_contents = directory.read_dir()?.filter_map(|e| e.ok()).map(|p| {
        let pb = p.path();
        let path = pb.as_path();
        let name = p.file_name().to_string_lossy().to_string();
        let name_length = unicode_width::UnicodeWidthStr::width(name.as_str());

        let formatted_name = if let Some(s) = ls_colors.style_for_path(path) {
            s.to_nu_ansi_term_style().paint(&name).to_string()
        } else {
            name
        };
        GridItem {
            string: formatted_name,
            length: name_length,
        }
    });
    // .map(|e| e.path().to_string_lossy().to_string());

    if let Some(g) = print_grid(directory_contents, term_props.columns) {
        Ok(g)
    } else {
        Err(error::TuError::custom("Failed to print grid"))
    }
}

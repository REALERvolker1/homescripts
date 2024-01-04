use crate::*;
use ahash::AHashMap;
use lscolors;
use std::{env, ffi::OsStr, fs::DirEntry, path::*, rc::Rc};
#[derive(Debug, Default)]
pub enum EntryOption {
    Entry(Rc<PathBuf>),
    #[default]
    Empty,
}
impl EntryOption {
    // pub fn path(&self) -> PathBuf {
    //     match self {
    //         EntryOption::Entry(x) => x.path(),
    //         EntryOption::PathBuf(x) => x.to_path_buf(),
    //     }
    // }
    // pub fn from_direntry(direntry: &Option<DirEntry>) -> Self {
    //     match direntry {
    //         Some(x) => EntryOption::Entry(*x),
    //         None => EntryOption::Empty,
    //     }
    // }
    fn into_data_types_i_actually_need(&self) -> (Option<Rc<PathBuf>>, Rc<String>, usize) {
        match self {
            EntryOption::Entry(path) => {
                let (file_name, name_width) = if let Some(name) = path.file_name() {
                    let lossy_name = name.to_string_lossy();
                    let lossy_name_length = lossy_name.chars().count();
                    let name_string = lossy_name.to_string();
                    (name_string, lossy_name_length)
                } else {
                    ("".to_owned(), 0)
                };
                // let name = x.file_name();
                // let lossy_name = name.to_string_lossy();
                // let lossy_name_length = lossy_name.chars().count();
                // let name_string = lossy_name.to_string();

                (Some(Rc::clone(&path)), Rc::new(file_name), name_width)
            }
            EntryOption::Empty => (None, Rc::new("".to_owned()), 0),
        }
    }
}

#[derive(Debug, Clone)]
pub struct ColumnEntry {
    pub name: Rc<String>,
    pub formatted: Rc<String>,
    pub is_dir: bool,
    /// The first letter to sort by, notably omitting the dot if possibl
    pub first_letter: Option<char>,
}

#[derive(Debug, Clone)]
pub struct Column {
    pub contents: Vec<ColumnEntry>,
    pub width: usize,
}
impl Column {
    /// Really only used for like one internal function, which is why the API isn't very ergonomic
    pub fn from_contents(
        dir_contents: Vec<EntryOption>,
        ls_colors: &lscolors::LsColors,
        default_style: &lscolors::Style,
        current_width: usize,
        max_width: usize,
    ) -> Option<Self> {
        let contents = dir_contents
            .iter()
            .map(|e| e.into_data_types_i_actually_need())
            .collect::<Vec<_>>();

        let my_max_width = contents.iter().map(|x| x.2).max().unwrap_or(0);
        let my_padded_width = my_max_width + constants::PAD_SPACES_DOUBLED;

        // don't calculate if it's already too big
        if current_width + my_padded_width > max_width {
            return None;
        }

        let entries = contents
            .iter()
            .map({
                |(path_opt, filename, width)| {
                    let styled_string = Rc::new(if let Some(p) = path_opt {
                        let style = ls_colors
                            .style_for_path(p.as_path())
                            .unwrap_or(default_style);
                        let painted = style
                            .to_nu_ansi_term_style()
                            .paint(filename.as_str())
                            .to_string();

                        let pad_width = my_max_width - *width;

                        format!(
                            "{}{}{:pad_width$}{}",
                            constants::PAD_SPACE,
                            painted,
                            "",
                            constants::PAD_SPACE
                        )
                        // .to_owned() + &painted + &" ".repeat(pad_width)
                    } else {
                        // Any empty columns should be padded with spaces too for consistency
                        " ".repeat(my_padded_width)
                    });
                    // (filename, styled_string)
                    ColumnEntry {
                        name: Rc::clone(filename),
                        formatted: styled_string,
                        is_dir: path_opt.is_some(),
                        first_letter: filename.chars().next(),
                    }
                }
            })
            .collect::<Vec<_>>();

        Some(Self {
            contents: entries,
            width: my_padded_width,
        })
    }
}

#[derive(Debug, Clone)]
pub struct DirContent {
    pub columns: Vec<Column>,
    pub surplus: usize,
    pub width: usize,
    pub max_width: usize,
    pub should_fill_width: bool,
    pub height: usize,
}
impl DirContent {
    pub fn table_format(&self) -> Vec<String> {
        let mut display: AHashMap<usize, Vec<_>> = AHashMap::with_capacity(self.height);

        for column in self.columns.iter() {
            let mut current_height = 0;
            for entry in column.contents.iter() {
                display
                    .entry(current_height)
                    .or_insert(Vec::new())
                    .push(entry);
                current_height += 1;
            }
        }
        let display_contents: Vec<String> = if self.should_fill_width {
            // should fill the width of the entire window,
            // add an extra space to the end if one is even and the other is odd to make them flush
            // let mut column_widths = self.max_width;
            let widths = self.columns.iter().map(|x| x.width).collect::<Vec<_>>();
            let column_widths = widths.iter().fold(0, |acc, i| acc + i);
            let width_diff = self.max_width - column_widths;
            debug_assert!(width_diff > 0);

            let extra_pad = if column_widths % 2 == self.max_width % 2 {
                0
            } else {
                1
            };
            // plus 1 for space around
            let num_constituents = widths.len() + 1;
            let (pad_start, pad_between, pad_end, extra) = if width_diff < num_constituents {
                // Each must have at least a single space between them. If not, just pad the sides.
                let div2 = width_diff / 2;
                (div2, 0, div2 + extra_pad, 0)
            } else {
                let equal_padding_width = width_diff / num_constituents;
                let extra = width_diff % num_constituents;
                (
                    equal_padding_width,
                    equal_padding_width,
                    equal_padding_width,
                    extra,
                )
            };

            display
                .iter()
                .map(|(k, v)| {
                    let mut remaining_extra = extra;

                    v.iter()
                        .map(|entry| {
                            let extra_space = if remaining_extra > 0 {
                                remaining_extra -= 1;
                                " "
                            } else {
                                ""
                            };
                            // could probably use a tuple here. I wanted to do iterator.flatten() but I'm using an Rc and I'm too far in to redesign
                            format!("{}{}", entry.formatted.as_str(), extra_space)
                        })
                        .collect::<Vec<_>>()
                        .join("")
                })
                .collect::<Vec<String>>()
        } else {
            display
                .iter()
                .map(|r| {
                    r.1.iter()
                        .map(|f| f.formatted.as_str())
                        .collect::<Vec<_>>()
                        .join("")
                })
                .collect::<Vec<String>>()
        };

        display_contents
    }
}

#[derive(Debug, Clone)]
pub struct DisplayWindow {
    pub contents: Vec<String>,
    pub width: usize,
    pub height: usize,
    pub cwd: PathBuf,
}
impl DisplayWindow {}
const FORMAT_WINDOW_SIDEPAD_WIDTH: usize = (constants::PAD_SPACES_WIDTH + 1) * 2;
pub fn format_window(
    contents: &Vec<String>,
    contents_width: usize,
    surplus: usize,
    cwd: &Path,
    hashed_dirs: &Vec<bruh::HashedDirectory>,
) -> String {
    let horiz = String::from(constants::BOX_DRAWING_CURVED.horizontal);

    // +1 (for the ilog10 plus the length of the integer) + 1 (for the '+') + 4 (for the strings on either side)
    // let surplus_length_full =
    //     surplus.checked_ilog10().unwrap() as usize + 2 + FORMAT_WINDOW_SIDEPAD_WIDTH;
    let surplus_length_full = surplus.to_string().len() + 2 + FORMAT_WINDOW_SIDEPAD_WIDTH;

    // don't show the surplus if it's super tiny lmao
    let (surplus_length, surplus_fmt_string) = if surplus_length_full > contents_width {
        let surplus_fmt = format!(
            "{}{}+{}{}{}",
            constants::BOX_DRAWING_CURVED.horizontal_intersection_right,
            constants::PAD_SPACE,
            surplus,
            constants::PAD_SPACE,
            constants::BOX_DRAWING_CURVED.horizontal_intersection_left
        );
        (surplus_length_full, surplus_fmt)
    } else {
        (0, "".to_owned())
    };
    let bottom_fmt_string = format!(
        "{}{}{}",
        constants::BOX_DRAWING_CURVED.bottom_left,
        &horiz.repeat(contents_width - surplus_length),
        constants::BOX_DRAWING_CURVED.bottom_right
    );

    // let mut current_path_display = "".to_owned();
    // let mut current_path_length = 0;
    // for dir in hashed_dirs.iter() {
    //     if cwd.starts_with(&dir.directory) {
    //         current_path_display = format!("~{}", &dir.key);
    //         current_path_length = dir.key_length + 1;
    //         break;
    //     }
    // }

    let cwd_lstring = cwd.to_string_lossy();

    // needs to be an owned value, the result from the vec is a reference
    let (path_prefix_base, path_prefixed_length) = if let Some(hd) = hashed_dirs
        .iter()
        .filter(|dir| cwd.starts_with(&dir.directory_string))
        .next()
    {
        let hd_fmt = format!("~{}", &hd.key);
        let cwd_rest = cwd_lstring.replacen(&hd.directory_string, &hd_fmt, 1);
        let width = cwd_rest.chars().count() + FORMAT_WINDOW_SIDEPAD_WIDTH;
        (cwd_rest, width)
    } else {
        (
            cwd_lstring.to_string(),
            cwd_lstring.chars().count() + FORMAT_WINDOW_SIDEPAD_WIDTH,
        )
    };
    let top_fmt_string = format!(
        "{}{}{}{}{}{}{}{}",
        constants::BOX_DRAWING_CURVED.top_left,
        &horiz.repeat(contents_width - path_prefixed_length),
        constants::BOX_DRAWING_CURVED.horizontal_intersection_right,
        constants::PAD_SPACE,
        &path_prefix_base,
        constants::PAD_SPACE,
        constants::BOX_DRAWING_CURVED.horizontal_intersection_left,
        constants::BOX_DRAWING_CURVED.top_right
    );

    format!(
        "{}\n{}\n{}",
        &top_fmt_string,
        contents
            .iter()
            .map(|i| format!(
                "{}{}{}",
                constants::BOX_DRAWING_CURVED.vertical,
                &i,
                constants::BOX_DRAWING_CURVED.vertical
            ))
            .collect::<Vec<_>>()
            .join("\n"),
        &bottom_fmt_string
    )
}

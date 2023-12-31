use crate::format;
use ahash::AHashMap;
use lscolors;
///! Bureaucratic stuff required to make this cli not suck
use std::{env, error, fmt, fs::DirEntry, io, path::*, rc::Rc};
use terminal_size;

/// An error type I kinda quickly threw together.
#[derive(Debug)]
pub enum PrintError {
    Io(io::Error),
    Env(env::VarError),
    ArgParse(String),
    Other(String),
}
impl error::Error for PrintError {}
impl From<io::Error> for PrintError {
    fn from(e: io::Error) -> Self {
        PrintError::Io(e)
    }
}
impl From<env::VarError> for PrintError {
    fn from(e: env::VarError) -> Self {
        PrintError::Env(e)
    }
}
impl fmt::Display for PrintError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            PrintError::Io(e) => e.fmt(f),
            PrintError::Env(e) => e.fmt(f),
            PrintError::ArgParse(e) => e.fmt(f),
            PrintError::Other(e) => e.fmt(f),
        }
    }
}

/// an enum to make sure I don't have to match against strings if I don't have to
#[derive(Debug)]
enum PrevArgType {
    Height,
    PercentHeight,
    None,
}

pub fn help(complaint: &str, arg: &str) -> PrintError {
    eprintln!("Usage: {0} [--options]
--term-width     Fill the width of the terminal window
--height <num>   Specify a height limit for the ls output.
--percent-height <num>   Specify a height limit for the output as a percentage of the terminal height

Height does not include borders, so running `{0} --height 3` will have a real height of 5.

Recommended to keep the height under 10 or something.
", env!("CARGO_BIN_NAME"));
    PrintError::ArgParse(format!("{}: {}", complaint, arg))
}

// macro_rules! another {
//     ($iterator:ident) => {
//         let mut contents = Vec::new(4);
//         if let Some(i) = $iterator.next() {
//             i
//         } else {}
//     };
// }

pub struct Options {
    pub max_width: usize,
    pub fill_width: bool,
    /// The max height, and max length of each column
    pub max_height: usize,
    pub dirs: Vec<Vec<DirEntry>>,
}
impl Options {
    pub fn dirs_next(
        &mut self,
        ls_colors: &lscolors::LsColors,
        default_style: &lscolors::Style,
    ) -> Option<format::DirContent> {
        let current_dirvec = if let Some(d) = self.dirs.pop() {
            d
        } else {
            return None;
        };
        let mut current = current_dirvec.iter();

        let mut table_width = 0;
        let mut current_column_vec = Vec::new();

        // let mut display: AHashMap<usize, Vec<format::ColumnEntry>> = AHashMap::with_capacity(self.max_height);

        loop {
            let mut entries = Vec::new();
            entries.reserve(self.max_height);

            for _idx in 0..self.max_height {
                if let Some(e) = current.next() {
                    entries.push(format::EntryOption::Entry(Rc::new(e.path().to_path_buf())));
                }
            }

            let entries_len = entries.len();
            let is_last = entries_len < self.max_height;

            if is_last {
                // fill with default so the width isn't messed up
                entries.resize_with(self.max_height, format::EntryOption::default);
            }

            if let Some(column) = format::Column::from_contents(
                entries,
                ls_colors,
                default_style,
                table_width,
                self.max_width,
            ) {
                table_width += column.width;
                current_column_vec.push(column);
            } else {
                // if no column, we've run out of space
                break;
            };

            if is_last {
                break;
            }
        }

        let window = format::DirContent {
            columns: current_column_vec,
            width: table_width,
            max_width: self.max_width,
            should_fill_width: self.fill_width,
            height: self.max_height,
        };

        Some(window)
    }
    /// Parse the args to get the options
    pub fn from_args() -> Result<Self, PrintError> {
        let mut fill_width = false;
        let mut max_height = 4;
        let mut height_as_percent = false;
        let mut dirs = Vec::new();

        let mut args = env::args().skip(1);
        while let Some(arg) = args.next() {
            match arg.as_str() {
                "--term-width" => fill_width = true,
                "--height" => {
                    if let Some(next_arg) = args.next() {
                        if let Ok(h) = next_arg.parse::<usize>() {
                            height_as_percent = false;
                            max_height = h;
                            continue;
                        }
                    }
                    return Err(help("Argument requires a number value", &arg));
                }
                "--percent-height" => {
                    if let Some(next_arg) = args.next() {
                        if let Ok(h) = next_arg.parse::<usize>() {
                            // since it is parsing as usize, it will error if under zero
                            if h <= 100 {
                                height_as_percent = true;
                                max_height = h as usize;
                                continue;
                            }
                        }
                    }
                    return Err(help("Argument requires a value between 0 and 100", &arg));
                }
                _ => {
                    let path = PathBuf::from(&arg);
                    if path.is_dir() {
                        dirs.push(path)
                    } else {
                        return Err(help("Invalid arg or folder", &arg));
                    }
                }
            }
        }

        // if you aren't even in a real directory, your computer is messed up, dude
        if dirs.is_empty() {
            dirs.push(env::current_dir()?);
        }
        // read directories and reverse the iter, so I can just use x.pop() to remove dirs in the order required
        let dirs_read = dirs
            .iter()
            .filter_map(|e| e.read_dir().ok())
            .map(|e| e.filter_map(Result::ok).collect())
            .rev()
            .collect::<Vec<Vec<DirEntry>>>();

        let max_width = if let Some((terminal_size::Width(w), terminal_size::Height(h))) =
            terminal_size::terminal_size()
        {
            if height_as_percent {
                max_height = (h as usize / 100) * max_height;
            }

            // width minus 2 for the borders
            w as usize - 2
        } else {
            eprintln!("Failed to get terminal size. Setting somewhat reasonable default width");
            fill_width = false;
            if height_as_percent {
                max_height = max_height / 6;
            }
            78
        };

        Ok(Self {
            max_width,
            fill_width,
            max_height,
            dirs: dirs_read,
        })
    }
}

/// zsh hashed directories
#[derive(Debug, Clone)]
pub struct HashedDirectories {
    pub dirs: Vec<(String, PathBuf)>
}
impl HashedDirectories {
    pub fn only_home() -> Self {
        Self {
            dirs: vec![("home".to_owned(), env::h)],
        }
    }
}

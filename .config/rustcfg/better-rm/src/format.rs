use crate::prelude::*;
use term_grid::*;

type Lsc<'a> = Option<&'a LsColors>;

#[derive(Debug)]
pub struct FormattedPath {
    // I had to rewrite a bunch of code to use the owned pathbuf type because this is multi threaded
    pub path: Arc<PathBuf>,
    pub display_path: String,
    pub directory_list: Option<DirList>,
    pub is_dir: bool,
    pub is_symlink: bool,

    pub action: ActionType,
}
impl FormattedPath {
    pub fn new(path: &Arc<PathBuf>, is_verbose: bool, ls_colors: Lsc) -> Res<Self> {
        // if I can't write to it, I can't remove it, there is no point.
        if path.metadata()?.permissions().readonly() {
            bail!("{} is read-only", path.display())
        }

        let str_path = path.to_string_lossy();
        let display_path = path_style_recursively(path, ls_colors).unwrap_or(str_path.to_string());
        let is_dir = path.is_dir();
        let is_symlink = path.is_symlink();

        let directory_list = if is_verbose && is_dir && !is_symlink {
            match DirList::new(path, ls_colors) {
                Ok(d) => Some(d),
                Err(e) => {
                    eprintln!("{e}");
                    None
                }
            }
        } else {
            None
        };

        Ok(Self {
            path: Arc::clone(path),
            display_path,
            directory_list,
            is_dir,
            is_symlink,
            action: ActionType::Skip,
        })
    }
    pub fn set_action(mut self, action: ActionType) -> Self {
        self.action = action;
        self
    }
    pub fn display_minimal<'a>(&'a self) -> &'a str {
        &self.display_path
    }
}
impl fmt::Display for FormattedPath {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if let Some(d) = &self.directory_list {
            write!(f, "{}\n{}", self.display_path, d)
        } else {
            write!(f, "{}", self.display_path)
        }
    }
}

/// Meant to be a subdir or subfile of a FormattedPath. Only shows the name, not the full path.
#[derive(Debug)]
pub struct MiniFormattedPath {
    pub display_path: String,
    pub is_writable: bool,
}
impl MiniFormattedPath {
    pub fn new(path: &Path, ls_colors: Lsc) -> Res<Self> {
        let file_name = if let Some(n) = path.file_name() {
            n.to_string_lossy()
        } else {
            bail!("{} has no filename!", path.display())
        };

        let metadata = path.metadata()?;

        let display_path = if let Some(lsc) = ls_colors {
            let style = lsc
                .style_for_path_with_metadata(path, Some(&metadata))
                .unwrap_or(&lscolors::Style::default())
                .to_nu_ansi_term_style();

            if let Ok(d) = path.read_dir() {
                let count = d.filter(|p| p.is_ok()).count();
                format!(
                    "{} {}{}{}",
                    style.paint(file_name),
                    style.paint("("),
                    dir_count_str(count, true),
                    style.paint(")")
                )
            } else {
                style.paint(file_name).to_string()
            }
        } else {
            file_name.to_string()
        };

        Ok(Self {
            display_path,
            is_writable: !metadata.permissions().readonly(),
        })
    }
}
impl fmt::Display for MiniFormattedPath {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", &self.display_path)
    }
}
impl AsRef<str> for MiniFormattedPath {
    fn as_ref(&self) -> &str {
        self.display_path.as_str()
    }
}

#[derive(Debug)]
pub struct DirList {
    pub total_count: usize,
    pub count_str: String,
    pub contents: Vec<MiniFormattedPath>,
}
impl DirList {
    pub fn new(path: &Path, ls_colors: Lsc) -> Res<Self> {
        let mut contents = Vec::new();

        for i in path.read_dir()? {
            match i {
                Ok(p) => match MiniFormattedPath::new(&p.path(), ls_colors) {
                    Ok(p) => contents.push(p),
                    Err(e) => return Err(e),
                },
                Err(e) => return Err(e.into()),
            }
        }

        let total_count = contents.len();

        Ok(Self {
            total_count,
            count_str: dir_count_str(total_count, ls_colors.is_some()).to_string(),
            contents,
        })
    }
}
impl fmt::Display for DirList {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let (width, _) = crate::config::term_size();

        let grid = Grid::new(
            self.contents.iter().map(|p| p.as_ref()).collect::<Vec<_>>(),
            GridOptions {
                direction: Direction::TopToBottom,
                filling: Filling::Spaces(2),
                width: width.0 as usize,
            },
        );
        write!(f, "{grid}\n{} items total", &self.count_str)
    }
}

// pub fn ls(path: &Path) -> Result<>

/// Style a full filepath. Will return None if the user chose not to have it colored.
pub fn path_style_recursively(path: &Path, ls_colors: Lsc) -> Option<String> {
    let p = ls_colors?
        .style_for_path_components(path)
        .map(|(p, s)| {
            s.unwrap_or(&lscolors::Style::default())
                .to_nu_ansi_term_style()
                .paint(p.to_string_lossy())
                .to_string()
        })
        .collect::<Vec<_>>()
        .join("");
    Some(p)
}

pub fn dir_count_str<'a>(num: usize, is_colored: bool) -> Box<dyn fmt::Display + 'a> {
    if !is_colored {
        return Box::new(num);
    }

    let color = if num < 15 {
        nu_ansi_term::Color::LightGreen
    } else if num < 30 {
        nu_ansi_term::Color::LightYellow
    } else if num < 60 {
        nu_ansi_term::Color::LightRed
    } else {
        nu_ansi_term::Color::Red
    };
    Box::new(color.bold().paint(num.to_string()))
}

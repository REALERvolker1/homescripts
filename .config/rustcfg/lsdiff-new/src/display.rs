use std::{
    borrow::Cow,
    cell::Cell,
    fs::DirEntry,
    io::{self, Seek},
    path::{Path, PathBuf},
};

// comptime type checking
pub trait ConstBool {}
pub struct True;
impl ConstBool for True {}
pub struct False;
impl ConstBool for False {}

pub struct PathListEntry<B: ConstBool> {
    pub pdisp: PathDisplay,
    pub _init_state: std::marker::PhantomData<B>,
}

pub struct PartialPathDisplay<'s> {
    pub path: &'s Path,
    pub name: &'s str,
    kind: PathKind,
}
impl<'s> PartialPathDisplay<'s> {
    pub fn from_line(line: &'s str) -> Option<Self> {
        let mut split = line.split(' ');
        let kind = PathKind::variant_from_idx_unchecked(split.next()?.parse::<usize>().ok()?);
        let name = split.next()?;

        if name.is_empty() {
            return None;
        }

        Some(Self {
            path: Path::new(name),
            name,
            kind,
        })
    }
}

pub struct PathDisplay {
    pub name: String,
    pub width: usize,
    pub kind: PathKind,
    pub delta: PathTransformation,
}
impl PathDisplay {
    pub fn new(path: PathBuf) -> Self {
        let kind = PathKind::kind_for_path(&path);
        let name = file_name(&path);

        let width = name.chars().count();

        Self {
            name,
            width,
            kind,
            delta: PathTransformation::Unchanged,
        }
    }

    pub fn from_ppd(ppd: PartialPathDisplay<'_>) -> Self {
        Self {
            width: ppd.name.chars().count(),
            name: ppd.name.to_owned(),
            kind: ppd.kind,
            delta: PathTransformation::Unchanged,
        }
    }

    #[inline(always)]
    pub fn change_kind(&mut self, kind: PathKind) {
        self.kind = kind;
        self.delta = PathTransformation::Change;
    }

    /// Returns bool showing if the kind changed, returns None if they do not match.
    #[inline]
    pub fn ppd_kind_changed(&self, ppd: &PartialPathDisplay<'_>) -> Option<bool> {
        if ppd.name == self.name {
            return Some(ppd.kind == self.kind);
        }
        None
    }
    #[inline(always)]
    pub fn ppd_is_me(&self, ppd: &PartialPathDisplay<'_>) -> bool {
        ppd.name == self.name
    }
}

fn file_name(path: &Path) -> String {
    match path.file_name() {
        Some(n) => n.to_string_lossy().into_owned(),
        None => {
            let pathsstr = path.to_string_lossy();
            let Some(slashidx) = pathsstr.find('/') else {
                return pathsstr.into_owned();
            };

            pathsstr[slashidx + 1..].into()
        }
    }
}

pub fn cmp_directory<'c>(
    current_entries: Vec<PathDisplay>,
    config_contents: Vec<PartialPathDisplay<'c>>,
) -> io::Result<Vec<PathDisplay>> {
    let mut out = Vec::with_capacity(current_entries.len().abs_diff(config_contents.len()));

    for mut entry in current_entries {
        if let Some(ppd) = config_contents.iter().find(|ppd| entry.ppd_is_me(ppd)) {
            entry.change_kind(ppd.kind);
        }
        entry.delta = PathTransformation::Add;
        out.push(entry);
    }
    todo!();
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum PathTransformation {
    Unchanged,
    Add,
    Remove,
    Change,
}

// https://veykril.github.io/tlborm/decl-macros/building-blocks/counting.html
macro_rules! replace_expr {
    ($_t:tt $sub:expr) => {
        $sub
    };
}
macro_rules! count_tts {
    ($($tts:tt)*) => {0usize $(+ replace_expr!($tts 1usize))*};
}

macro_rules! makepathkind {
    ($( $kind:ident: $icon:expr ),+$(,)?) => {
        #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
        pub enum PathKind {
            $( $kind ),+
        }
        impl PathKind {
            pub const PATHKIND_COUNT: usize = count_tts!($( $icon )+);
            pub const ICON_ARRAY: [char; Self::PATHKIND_COUNT] = [$( $icon ),+];
            pub const VARIANT_ARRAY: [PathKind; Self::PATHKIND_COUNT] = [$( Self::$kind ),+];
        }
    };
}

makepathkind! {
    NonExistent: '󱪢',
    Directory: '',
    File: '󰈙',
    SymlinkDirectory: '󱧬',
    SymlinkFile: '󱅷',
    DotFile: '󰘓',
    DotFolder: '󱞞',
}
impl PathKind {
    /// Panics if the index is out of bounds
    #[inline(always)]
    pub const fn icon_from_idx_unchecked(i: usize) -> char {
        Self::ICON_ARRAY[i]
    }

    #[inline(always)]
    pub const fn variant_from_idx_unchecked(i: usize) -> Self {
        Self::VARIANT_ARRAY[i]
    }

    pub fn kind_for_path(path: &Path) -> Self {
        if !path.exists() {
            return Self::NonExistent;
        }

        // dotfiles take precedent
        if let Some(fname) = path.file_name() {
            if fname.to_string_lossy().starts_with('.') {
                if path.is_dir() {
                    return Self::DotFolder;
                } else {
                    return Self::DotFile;
                }
            }
        }

        if path.is_symlink() {
            if path.is_dir() {
                return Self::SymlinkDirectory;
            } else {
                return Self::SymlinkFile;
            }
        }

        if path.is_dir() {
            return Self::Directory;
        }
        if path.is_file() {
            return Self::File;
        }

        Self::NonExistent
    }

    #[inline(always)]
    pub const fn as_idx(&self) -> usize {
        *self as usize
    }

    #[inline(always)]
    pub const fn as_icon(&self) -> char {
        Self::icon_from_idx_unchecked(self.as_idx())
    }
}

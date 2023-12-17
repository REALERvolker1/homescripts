use crossterm;
use file_type_enum::FileType;
use lscolors;
use std::{
    io,
    os::{self, unix::fs::MetadataExt},
    path::{Path, PathBuf},
};

/// padding so the icon can be seen
pub const ICON_PADDING: &str = " ";
/// the length of the ICON_PADDING string
pub const ICON_PADDING_LENGTH: usize = 1;

/// Change this if the return type of IconType::get_icon() changes
pub const ICON_LENGTH: usize = 1;

/// someday I hope this code is obsoleted by `eza` supporting their library
#[derive(Debug)]
pub enum IconType {
    File,
    FileEmpty,
    Dir,
    DirEmpty,
    DirReadError,
    LinkBroken,
    Nonexistent,
    Other,

    Exec,
    FIFO,
    Socket,
    Device,

    // requires file extensions
    FileAudio,
    FileVideo,
    FileImage,
    FileArchive,
    FileDisk,
    FileDocument,
    FileData,
}
impl IconType {
    pub fn get_icon(&self) -> char {
        match self {
            IconType::File => '󰈔',
            IconType::FileEmpty => '󰈤',
            IconType::Dir => '󰉋',
            IconType::DirEmpty => '󰷏',
            IconType::DirReadError => '󰷍',
            IconType::LinkBroken => '󰌺',
            IconType::Nonexistent => '󰳤',
            IconType::Other => '󱀶',
            IconType::Exec => '󱀮',
            IconType::FIFO => '󰟥',
            IconType::Socket => '󰱠',
            IconType::Device => '󰇅',
            IconType::FileAudio => '󰈣',
            IconType::FileVideo => '󰈫',
            IconType::FileImage => '󰈟',
            IconType::FileArchive => '󰛫',
            IconType::FileDisk => '󰋊',
            IconType::FileDocument => '󰈙',
            IconType::FileData => '󰱾',
        }
    }
    /// This function strongly depends on data from File::new()
    fn new(filepath: &Path, filepath_str: &str, is_symlink: bool, file_type: FileType) -> Self {
        if filepath.exists() {
            let file_type_first_attempt = match file_type {
                FileType::Directory => {
                    if let Ok(contents) = filepath.read_dir() {
                        if contents.count() == 0 {
                            Some(IconType::DirEmpty)
                        } else {
                            Some(IconType::Dir)
                        }
                    } else {
                        // probably doesn't have read permissions
                        Some(IconType::DirReadError)
                    }
                }
                FileType::Fifo => Some(IconType::FIFO),
                FileType::Socket => Some(IconType::Socket),
                FileType::BlockDevice | FileType::CharDevice => Some(IconType::Device),
                _ => None,
            };

            if let Some(icon_type) = file_type_first_attempt {
                icon_type
            } else if let Ok(metadata) = filepath.metadata() {
                if os::unix::fs::MetadataExt::size(&metadata) == 0 {
                    IconType::FileEmpty
                } else {
                    // check if the file has executable permissions by looking at its octal perms
                    let octal_permissions = os::unix::fs::MetadataExt::mode(&metadata);
                    // only match the first digit
                    match octal_permissions / 0o100 {
                        1 | 3 | 5 | 7 => IconType::Exec,
                        _ => IconType::from_extension(filepath),
                    }
                }
            } else {
                IconType::from_extension(filepath)
            }
        } else if is_symlink {
            IconType::LinkBroken
        } else {
            IconType::Nonexistent
        }
    }
    /// ONLY PUT PATHS TO REGULAR FILES IN HERE! DOES NOT WORK ON DIRECTORIES!!!!!!
    fn from_extension(filepath_not_a_directory: &Path) -> Self {
        let ext_option = if let Some(file_extension) = filepath_not_a_directory.extension() {
            if let Some(file_extension_str) = file_extension.to_str() {
                // match by extension, mime types could be good, but the mime crate basically does the same thing as this
                match file_extension_str.to_ascii_lowercase().as_str() {
                    "mp3" | "wav" | "ogg" | "flac" | "aac" | "wma" | "m4a" | "opus" => {
                        Some(IconType::FileAudio)
                    }
                    "webm" | "mkv" | "mp4" | "avi" | "mov" | "wmv" | "flv" | "mpg" | "mpeg"
                    | "m4v" => Some(IconType::FileVideo),
                    "jpg" | "jpeg" | "png" | "gif" | "bmp" | "ico" | "svg" | "webp" | "tif"
                    | "tiff" | "avif" | "heic" => Some(IconType::FileImage),
                    "tar" | "tgz" | "gz" | "bz2" | "zip" | "xz" | "7z" | "rar" | "zst" | "zstd"
                    | "lzma" | "lz" | "bz" | "jar" | "rpm" | "deb" | "apk" => {
                        Some(IconType::FileArchive)
                    }
                    "iso" | "img" | "dmg" | "qemu" | "qcow" | "qcow2" | "hdd" | "vhd" | "vdi" => {
                        Some(IconType::FileDisk)
                    }
                    "pdf" | "doc" | "docx" | "xls" | "xlsx" | "ppt" | "pptx" | "odt" | "ods"
                    | "odp" | "rtf" | "tex" | "md" | "org" | "epub" | "ipynb" => {
                        Some(IconType::FileDocument)
                    }
                    "json" | "jsonc" | "json5" | "yaml" | "yml" | "ini" | "toml" | "ron"
                    | "xml" | "csv" => Some(IconType::FileData),
                    _ => None,
                }
            } else {
                None
            }
        } else {
            None
        };
        if let Some(icon_type) = ext_option {
            icon_type
        } else {
            IconType::File
        }
    }
}

/// The representation of a stylable file, with all the info I need
#[derive(Debug)]
pub struct File {
    pub name: String,
    pub full_name: String,
    pub path: PathBuf,
    pub is_symlink: bool,
    // important so I don't have to do extra formatting if I don't have to
    pub name_fmt_length: usize,
}
impl File {
    pub fn new(filepath: &Path) -> Option<Self> {
        if let Some(filepath_str) = filepath.to_str() {
            if let Some(file_name_osstr) = filepath.file_name() {
                if let Some(file_name) = file_name_osstr.to_str() {
                    return Some(Self {
                        name: file_name.to_owned(),
                        full_name: filepath_str.to_owned(),
                        path: filepath.to_path_buf(),
                        is_symlink: filepath.is_symlink(),
                        name_fmt_length: file_name.chars().count()
                            + ICON_PADDING_LENGTH
                            + ICON_LENGTH,
                    });
                }
            }
        }
        None
    }

    /// format the filepath using LS_COLORS. Please check if there is enough space in the terminal first
    pub fn fmt_with_colors(&self, ls_colors: &lscolors::LsColors) -> String {
        let filepath = self.path.as_path();
        let filepath_str = &self.full_name;

        let file_icon_type = if let Ok(file_type) = FileType::symlink_read_at(filepath) {
            IconType::new(filepath, filepath_str, self.is_symlink, file_type)
        } else {
            IconType::from_extension(filepath)
        };

        let name_with_icon = format!("{} {}", file_icon_type.get_icon(), &self.name);
        let fmt_name: String = if let Some(style) = ls_colors.style_for_path(self.path.as_path()) {
            style
                .to_crossterm_style()
                .apply(&name_with_icon)
                .to_string()
        } else {
            name_with_icon
        };
        fmt_name
    }
}

// /// Get all the files in a directory. Not intended to be used outside of testing.
// fn get_dir_files(directory: &Path) -> Result<Vec<File>, io::Error> {
//     // TODO: only format the files I need to format, not all of them
//     let file_vec = directory
//         .read_dir()?
//         .filter_map(|file| file.ok())
//         .map(|file| File::new(file.path().as_path()))
//         .filter(|f| f.is_some())
//         .map(|f| f.unwrap())
//         .collect::<Vec<File>>();

//     Ok(file_vec)
// }

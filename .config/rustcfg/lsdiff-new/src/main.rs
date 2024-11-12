mod bitflag_stuff;

use ::core::cell::Cell;
use ::std::{
    borrow::Cow,
    ffi::OsStr,
    fs,
    io::{self, Write},
    os::unix::prelude::OsStrExt,
    path::{Path, PathBuf},
};

use crate::bitflag_stuff::BitflagThingy;
use ::lscolors::LsColors;
use ::owo_colors::{Style, Styled};

/// Data that is read directly from the cache
pub struct PathEntryCacheData<'d> {
    pub path: &'d Path,
    pub kind: BitflagThingy,
}
impl<'d> PathEntryCacheData<'d> {
    pub fn from_line(line: &'d [u8]) -> Option<Self> {
        if line.len() < 3 {
            return None;
        }

        Some(Self {
            path: Path::new(OsStr::from_bytes(&line[1..])),
            kind: line[0],
        })
    }
}

#[derive(Debug)]
pub struct PathEntryData<'d> {
    pub path: &'d Path,
    pub file_name: Cow<'d, str>,
    pub metadata: fs::Metadata,
    pub kind: BitflagThingy,
}

impl<'d> PathEntryData<'d> {
    pub fn from_partial(data: PathEntryCacheData<'d>) -> Option<Self> {
        let metadata = data.path.metadata().ok()?;
        let name = data.path.file_name()?;
        Some(Self {
            path: data.path,
            file_name: name.to_string_lossy(),
            kind: data.kind,
            metadata,
        })
    }
    pub fn from_path(path: &'d Path) -> Option<Self> {
        let metadata = path.metadata().ok()?;
        let name = path.file_name()?;
        Some(Self {
            path,
            file_name: name.to_string_lossy(),
            kind: crate::bitflag_stuff::kind_for_metadata_with_name(
                &metadata,
                name.as_encoded_bytes(),
            ),
            metadata,
        })
    }

    pub fn write_to_buffer(&self, buffer: &mut impl Write) -> io::Result<()> {
        buffer.write_all(&[self.kind | crate::bitflag_stuff::PK_IS_CACHED])?;
        buffer.write_all(self.path.as_os_str().as_bytes())?;
        Ok(())
    }

    pub fn apply_color(&'d self, lscolors: &LsColors) -> Styled<&'d str> {
        let style = lscolors
            .style_for_path_with_metadata(self.path, Some(&self.metadata))
            .map(|s| s.to_owo_colors_style())
            .unwrap_or_default();

        return style.style(&self.file_name);
    }

    pub fn is_eq(&self, other: &Self) -> bool {
        self.path == other.path
            && self.file_name == other.file_name
            && (self.kind & crate::bitflag_stuff::PK_BITMASK_NOCACHE)
                == (other.kind & crate::bitflag_stuff::PK_BITMASK_NOCACHE)
    }
}

/// TODO: Show this to Mike
fn read_cachefile(home_folder: &Path) -> io::Result<(PathBuf, Vec<u8>)> {
    // use .push so I don't reallocated and move so much junk in the heap
    let mut cache_path = match ::std::env::var_os("XDG_CACHE_HOME") {
        Some(cache) => PathBuf::from(cache),
        None => home_folder.join(".cache"),
    };

    // You might be on a new Arch Linux installation or something, I gotchu
    if !cache_path.is_dir() {
        std::fs::create_dir_all(&cache_path)?;
    }

    cache_path.push(concat!(env!("CARGO_PKG_NAME"), ".bcache"));

    let rvec = if cache_path.is_file() {
        std::fs::read(&cache_path)?
    } else {
        // creating new vecs does not allocate anything unless you push to them
        Vec::new()
    };

    Ok((cache_path, rvec))
}

fn write_cachefile(path: &Path, data: Vec<PathBuf>) -> io::Result<()> {
    let mut fh = fs::File::create(path)?;
    let next_error = data
        .iter()
        .filter_map(|p| PathEntryData::from_path(p))
        .map(|d| {
            d.write_to_buffer(&mut fh)?;
            fh.write(b"\n")?;
            Ok(())
        })
        .find(Result::is_err);

    if let Some(e) = next_error {
        return e;
    }

    fh.flush()?;

    Ok(())
}

// /// returns true if the entry does not exist
// fn filter_cache_data_out_of_dir(
//     entry: PathEntryData<'_>,
//     dir_content: Vec<Cell<Option<PathEntryData<'_>>>>,
// ) -> bool {
// }

fn main() -> io::Result<()> {
    let home_dir = PathBuf::from(::std::env::var_os("HOME").expect("HOME is not set!"));

    // We will need these no matter what here
    let mut dir_contents = fs::read_dir(&home_dir)?
        .filter_map(Result::ok)
        .map(|e| e.path())
        .collect::<Vec<_>>();

    let (cache_path, data_cache) = read_cachefile(&home_dir)?;

    // no diff!
    if data_cache.is_empty() {
        write_cachefile(&cache_path, dir_contents)?;
        return Ok(());
    }

    // let dir_content_display_refs = dir_contents
    //     .iter()
    //     .filter_map(|p| PathEntryData::from_path(p))
    //     .map(|e| Cell::new(Some(e)))
    //     .collect::<Vec<_>>();

    let cache_content = memchr::memchr_iter(b'\n', &data_cache)
        .filter_map(|i| PathEntryCacheData::from_line(&data_cache[..i]))
        .filter_map(|d| {
            let old_len = dir_contents.len();

            dir_contents.retain(|p| p != d.path);

            if old_len == dir_contents.len() {
                // The cached entry is not in the directory anymore!
                return Some(d);
            }
            None
        });

    let lscolors = LsColors::from_env().unwrap_or_default();

    Ok(())
}

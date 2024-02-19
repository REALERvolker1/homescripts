//! This module exists so I can make an informed decision about which files to remove from which threads.

use crate::prelude::*;
use std::mem;
use std::os::unix::fs::MetadataExt;

/// I kinda got carried away with making this all multithreaded lmao
#[derive(Debug)]
pub struct WeightedEntry {
    /// The actual weight
    pub size: Option<u64>,
    /// Literally just here to make sorting easier
    pub is_dir: bool,
    /// Kinda unnecessary probably
    pub is_symlink: bool,
    pub children: Option<Vec<WeightedEntry>>,
    pub path_buf: PathBuf,
}
impl WeightedEntry {
    pub fn new(path_buf: PathBuf) -> Res<Self> {
        let metadata = path_buf.metadata()?;
        if metadata.permissions().readonly() {
            return Err(eyre!("{} is readonly", path_buf.display()));
        }
        let is_symlink = metadata.is_symlink();
        let is_dir = metadata.is_dir();

        let children = if is_dir && !is_symlink {
            Some(Self::read_directory(&path_buf)?)
        } else {
            None
        };

        let size = if is_dir || is_symlink {
            None
        } else {
            Some(metadata.size())
        };

        Ok(Self {
            size,
            is_dir,
            is_symlink,
            children,
            path_buf,
        })
    }
    /// A version of [`std::fs::read_dir`] that fails immediately when it encounters an error, and returns a `Vec<WeightedEntry>`
    fn read_directory(dir: &Path) -> Res<Vec<Self>> {
        let mut out = Vec::new();
        let mut dir = fs::read_dir(dir)?;

        while let Some(entry) = dir.next().transpose()? {
            let weighted = Self::new(entry.path())?;
            out.push(weighted);
        }

        Ok(out)
    }

    pub fn into_weight_group_types(mut self) -> Vec<WeightGroupType> {
        // if we already know it's a file, then cool
        if !self.is_dir {
            return vec![WeightGroupType::File(self)];
        }

        let children = mem::replace(&mut self.children, None);
        let myself_vec = vec![WeightGroupType::Directory(self)];

        let childs = if let Some(c) = children {
            c.into_iter()
        } else {
            // This is an empty directory
            return myself_vec;
        };

        // we need to do this recursively
        let mut out = Vec::new();

        for child in childs {
            out.push(child.into_weight_group_types());
        }

        // remember to add self
        out.push(myself_vec);

        out.into_iter().flat_map(|x| x).collect()
    }
}

#[derive(Debug)]
pub struct WeightGroup {
    pub files: Vec<WeightedEntry>,
    pub directories: Vec<WeightedEntry>,
}
impl WeightGroup {
    pub fn from_wg_types(wgt: Vec<WeightGroupType>) -> Self {
        let mut files = Vec::new();
        let mut directories = Vec::new();

        for entry in wgt.into_iter() {
            match entry {
                WeightGroupType::File(f) => files.push(f),
                WeightGroupType::Directory(d) => directories.push(d),
            }
        }
        Self { files, directories }
    }
}

pub enum WeightGroupType {
    File(WeightedEntry),
    Directory(WeightedEntry),
}

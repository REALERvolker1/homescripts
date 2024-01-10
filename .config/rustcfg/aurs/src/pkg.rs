use raur::ArcPackage;
use serde::{Deserialize, Serialize};
use serde_binary::{self, binary_stream::Endian};
use std::{env, error, fmt, fs, io, path::*};

#[derive(Debug, Default, Clone, Deserialize, Serialize)]
pub struct Package {
    pub id: u32,
    pub name: String,
    pub package_base_id: u32,
    pub package_base: String,
    pub version: String,
    pub description: Option<String>,
    pub url: Option<String>,
    pub num_votes: u32,
    pub popularity: f64,
    pub out_of_date: Option<i64>,
    pub maintainer: Option<String>,
    pub submitter: Option<String>,
    pub first_submitted: i64,
    pub last_modified: i64,
    pub url_path: String,
    pub groups: Vec<String>,
    pub depends: Vec<String>,
    pub make_depends: Vec<String>,
    pub opt_depends: Vec<String>,
    pub check_depends: Vec<String>,
    pub conflicts: Vec<String>,
    pub replaces: Vec<String>,
    pub provides: Vec<String>,
    pub license: Vec<String>,
    pub keywords: Vec<String>,
    pub co_maintainers: Vec<String>,
}
impl Package {
    pub fn from_raurpkg(pkg: Package) -> Self {
        Self {
            id: pkg.id,
            name: pkg.name,
            package_base_id: pkg.package_base_id,
            package_base: pkg.package_base,
            version: pkg.version,
            description: pkg.description,
            url: pkg.url,
            num_votes: pkg.num_votes,
            popularity: pkg.popularity,
            out_of_date: pkg.out_of_date,
            maintainer: pkg.maintainer,
            submitter: pkg.submitter,
            first_submitted: pkg.first_submitted,
            last_modified: pkg.last_modified,
            url_path: pkg.url_path,
            groups: pkg.groups,
            depends: pkg.depends,
            make_depends: pkg.make_depends,
            opt_depends: pkg.opt_depends,
            check_depends: pkg.check_depends,
            conflicts: pkg.conflicts,
            replaces: pkg.replaces,
            provides: pkg.provides,
            license: pkg.license,
            keywords: pkg.keywords,
            co_maintainers: pkg.co_maintainers,
        }
    }
}

#[derive(Debug)]
pub struct Cache {
    pub path: PathBuf,
    file: PathBuf,
}
impl Cache {
    pub fn new(maybe_path: &str) -> io::Result<Self> {
        let mp = Path::new(maybe_path);
        let try_path = if mp.is_dir() {
            Some(mp)
        } else if let Some(p) = mp.parent() {
            if p.is_dir() {
                fs::create_dir(&mp)?;
                Some(mp)
            } else {
                None
            }
        } else {
            None
        };
        let path = if let Some(p) = try_path {
            p.to_path_buf()
        } else {
            let default = PathBuf::from(Self::get_default_path());
            if default == mp {
                panic!(
                    "Error, default cache path {} is invalid!",
                    default.display()
                );
            }
            eprintln!(
                "Error, provided cache path `{}` is invalid! Falling back to default. ({})",
                mp.display(),
                default.display()
            );
            fs::create_dir_all(&default)?;
            default
        };
        Ok(Self {
            path: path.to_path_buf(),
            file: path.join("cachefile"),
        })
    }
    pub fn get_default_path() -> String {
        env::var("AURS_CACHE_HOME").unwrap_or(
        env::var("XDG_CACHE_HOME").unwrap_or_else(|o| {
            eprintln!("Warning: XDG_CACHE_HOME is not set! Falling back to $HOME/.cache");
            env::var("HOME")
                .expect("Error, could not determine home directory! Please make sure environment variable '$HOME', or preferably '$XDG_CACHE_HOME' is set.")
                + "/.cache"
        }) + "/aurs",
    )
    }
    /// Deserializes the cachefile into a `Vec<Package>`.
    ///
    /// Special care is taken to ensure that the program panics if the cache file is corrupted, rather than clobbering possibly good data.
    pub fn read_cachefile(&self) -> eyre::Result<Vec<Package>> {
        let maybe_buffer = fs::read(&self.file);
        let buffer = if let Ok(p) = maybe_buffer {
            p
        } else if let Err(e) = maybe_buffer {
            if self.file.exists() {
                panic!(
                    "Error, cache file at `{}` exists but could not be read!",
                    self.file.display()
                );
            }
            return Err(e.into());
        } else {
            unreachable!()
        };

        let maybe_packages = serde_binary::from_vec(buffer, Endian::default());

        if let Ok(p) = maybe_packages {
            Ok(p)
        } else if let Err(e) = maybe_packages {
            if self.file.exists() {
                panic!(
                    "Error, cache file at `{}` exists but could not be parsed!",
                    self.file.display()
                );
            }
            Err(e.into())
        } else {
            unreachable!()
        }
    }
    pub fn write_cachefile(cachefile: &Path, packages: &Vec<Package>) -> eyre::Result<()> {
        let data = serde_binary::to_vec(packages, Endian::default());
        if let Ok(d) = data {
            fs::write(cachefile, d)?;
            Ok(())
        } else if let Err(e) = data {
            eprintln!("Error converting data to bytes");
            Err(e.into())
        } else {
            unreachable!()
        }
    }
}

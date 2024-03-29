mod argparse;
mod desktop;
mod disk;
mod entry;
mod kernel;
mod nvidia;
mod output;
mod term;
mod uptime;

use std::{
    fs,
    io::{self, Write},
    path::Path,
};

use entry::Entry;

fn main() {
    let options = argparse::ArgOptions::parse_args();
    let cached = CacheProperties::new(options.cachefile.as_deref());

    let term = term::get_term();
    let uptime = uptime::get_uptime();
    let desktop = desktop::get_xdg_desktop();

    // get them all in order
    output::print(vec![
        uptime,
        term,
        cached.disks,
        cached.nvidia,
        cached.kernel,
        desktop,
    ]);
}

pub struct CacheProperties {
    pub kernel: Entry,
    pub nvidia: Entry,
    pub disks: Entry,
}
impl CacheProperties {
    /// Read the cache file, parsing it too
    pub fn new(maybe_path: Option<&Path>) -> Self {
        if let Some(path) = maybe_path {
            let cache_lambda = || {
                // told to use cache, but could not read from cache
                let me = Self::fetch_content();
                if let Err(e) = me.store(path) {
                    eprintln!("Could not write to cache file: {e}");
                }
                me
            };

            return match fs::read_to_string(path) {
                Ok(s) => Self::from_ordered_lines(s).unwrap_or_else(cache_lambda),
                // told to cache but the file probably didn't exist or something
                Err(e) => {
                    #[cfg(debug_assertions)]
                    eprintln!("Failed to read cache: {e}");
                    cache_lambda()
                }
            };
        }

        Self::fetch_content()
    }
    /// This is a very dumb function, but it doesn't really have to get all fancy with parsing and whatnot.
    pub fn from_ordered_lines(inp: String) -> Option<Self> {
        #[cfg(debug_assertions)]
        eprintln!("Fetching cache content from cache");

        let mut lines = inp.lines();
        Some(Self {
            kernel: Entry::new("Kernel", lines.next()?.to_owned()),
            nvidia: Entry::new("Nvidia", lines.next()?.to_owned()),
            disks: Entry::new("Disk", lines.next()?.to_owned()),
        })
    }
    pub fn fetch_content() -> Self {
        #[cfg(debug_assertions)]
        eprintln!("Fetching cache content from system");

        Self {
            kernel: kernel::get_kernel(),
            nvidia: nvidia::get_nvidia(),
            disks: disk::get_disk(),
        }
    }
    pub fn store(&self, path: &Path) -> io::Result<()> {
        if !path.exists() {
            if let Some(parent) = path.parent() {
                if !parent.is_dir() {
                    fs::create_dir_all(parent)?;
                }
            }
        }
        let mut file = fs::File::create(path)?;
        write!(
            file,
            "{}\n{}\n{}\n",
            self.kernel.content, self.nvidia.content, self.disks.content
        )
    }
}

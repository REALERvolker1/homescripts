use const_format::{concatcp, formatcp};
use std::{env, path::PathBuf};

pub struct ArgOptions {
    pub cachefile: Option<PathBuf>,
}
impl ArgOptions {
    pub fn parse_args() -> Self {
        let mut check_cache = true;
        let mut cachefile = None;

        let mut args = env::args().skip(1);
        while let Some(arg) = args.next() {
            match arg.as_str() {
                "--no-cache" => check_cache = false,
                "--cache" => {
                    let Some(maybe_path) = args.next() else {
                        panic!("error: missing cache path!");
                    };
                    check_cache = true;
                    cachefile = Some(PathBuf::from(maybe_path));
                }
                _ => {
                    const HELP_TEXT: &str = concatcp!(
                        formatcp!("{}\t{}\n", "--no-cache", "disable cache"),
                        formatcp!("{}\t{}\n", "--cache <path>", "use a cache file at <path>"),
                    );
                    panic!("error: unknown argument: {arg}\n\n{HELP_TEXT}");
                }
            }
        }

        if !check_cache {
            return Self { cachefile: None };
        }

        if cachefile.is_some() {
            return Self { cachefile };
        }

        let mut runtime_dir = match env::var_os("XDG_RUNTIME_DIR") {
            Some(var) => PathBuf::from(var),
            None => env::temp_dir(),
        };

        const BIN: &str = env!("CARGO_PKG_NAME");

        let bin_name = match env::var_os("XDG_SESSION_ID") {
            Some(id) => format!("{BIN}-{}.cache", id.to_string_lossy()),
            None => format!("{BIN}.cache"),
        };

        runtime_dir.push(bin_name);

        Self {
            cachefile: Some(runtime_dir),
        }
    }
}

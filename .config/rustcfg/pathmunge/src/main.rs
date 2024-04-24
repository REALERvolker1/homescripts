//! A path-validation program I don't use in my shell

use std::{env, io::Write, path::PathBuf};
const ENV_VAR: &str = "PATHMUNGE_PATH";

fn main() {
    let input_path_var = env::var_os(ENV_VAR).unwrap_or_else(|| {
        panic!(
            "Usage: {ENV_VAR}=\"$PATH\" {} /path/to/bin /path/to/other/bin...",
            env!("CARGO_BIN_NAME")
        )
    });

    let mut output = Vec::with_capacity(8);

    let arg_paths = env::args_os().skip(1).map(PathBuf::from);

    let input_paths = env::split_paths(&input_path_var)
        .chain(arg_paths)
        .filter(|p| p.is_dir())
        .filter_map(|p| p.canonicalize().ok());

    for path in input_paths {
        if !output.contains(&path) {
            output.push(path);
        }
    }

    let mut strung = output
        .into_iter()
        .map(PathBuf::into_os_string)
        .map(|p| {
            let mut bytes = p.into_encoded_bytes();
            bytes.push(':' as u8);
            bytes
        })
        .flatten()
        .collect::<Vec<_>>();

    let strung_len = strung.len() - 1;

    let last_byte = unsafe { strung.get_unchecked_mut(strung_len) };
    *last_byte = '\n' as u8;

    std::io::stdout().write_all(strung.as_slice()).unwrap();
}

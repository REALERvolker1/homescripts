//! A path-validation program I don't use in my shell

use std::{env, path::Path};
fn main() {
    let mut uvec = Vec::with_capacity(8);

    let paths = env::args()
        .skip(1)
        .filter_map(|i| {
            let i_path = Path::new(&i);
            if let Ok(c) = i_path.canonicalize() {
                if c.is_dir() {
                    // return the realpath if it is a directory
                    return Some(i);
                }
            }

            return None;
        })
        .for_each(|p| {
            if !uvec.contains(&p) {
                uvec.push(p)
            }
        });

    println!("{}", uvec.join(":"))
}

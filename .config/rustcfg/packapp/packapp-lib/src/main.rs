use std::{
    env, error,
    path::{Path, PathBuf},
};

mod formatting;
mod package;

fn main() -> Result<(), Box<dyn error::Error>> {
    // println!("Hello, world!");
    let bins = package::search_path(&["dnf", "pacman", "flatpak"]);

    let mut count = 0;
    for (key, val) in bins {
        let key_color = formatting::Color {
            foreground: Some(255),
            background: Some(count + 45),
            bold: true,
            dim: true,
        };
        let val_color = formatting::Color {
            foreground: Some(255),
            background: Some(count + 105),
            bold: false,
            dim: true,
        };
        let keyster = formatting::powerline_fmt(
            key_color,
            false,
            "",
            key.to_str().unwrap_or_default(),
            Some(val_color),
        );
        let valster =
            formatting::powerline_fmt(val_color, true, "", val.to_str().unwrap_or_default(), None);

        println!("{}{}", keyster, valster);
        // println!("Key: {:?}, val: {:?}", &key, &val);
    }
    Ok(())
}

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn it_works() {
//         let result = add(2, 2);
//         assert_eq!(result, 4);
//     }
// }

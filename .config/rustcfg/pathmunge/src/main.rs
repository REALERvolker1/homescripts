/*
vlk PATHMUNGE function for making deduplicating and validating $PATHlike (example: /path/dir:/usr/bin:/usr/share) variables are alright
*/
use std::{env, error, io, path::Path};

fn main() -> Result<(), Box<dyn error::Error>> {
    let mut path_vec = Vec::new();
    for arg in env::args().skip(1) {
        if arg.starts_with("--pathlike=") {
            let pathlikevar = arg.replacen("--pathlike=", "", 1);
            let mut pthvc = pathlikevar
                .split(":")
                .filter_map(|i| check_legit(i, &path_vec).ok())
                .collect::<Vec<String>>();
            path_vec.append(&mut pthvc);
        } else if let Ok(tmppth) = check_legit(&arg, &path_vec) {
            path_vec.push(tmppth)
        }
    }
    println!("{}", path_vec.join(":"));
    Ok(())
}

fn check_legit(dirpathstr: &str, pathvec: &Vec<String>) -> io::Result<String> {
    let dirpath = Path::new(dirpathstr);
    if dirpath.read_dir()?.next().is_none() {
        Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "Could not add to path",
        ))
    } else {
        let cpath = dirpath.canonicalize()?.to_string_lossy().to_string();
        if let Some(_) = pathvec.contains(&cpath).then_some("") {
            Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "Could not add to path",
            ))
        } else {
            Ok(cpath)
        }
    }
}

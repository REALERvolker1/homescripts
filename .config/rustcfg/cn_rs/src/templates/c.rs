use super::*;

const PRELUDE_H: &str = include_str!("../../templatesrc/c/prelude.h");
const MAIN_C: &str = include_str!("../../templatesrc/c/main.c");
const BUILDSCRIPT: &str = include_str!("../../templatesrc/c/build.sh");

pub struct CSimpleTemplate;
// impl Template for CSimpleTemplate {
//     fn name(&self) -> &str {
//         "C project"
//     }
//     fn description(&self) -> &str {
//         "A simple C project using a simple bash script as a \"build system\""
//     }
//     fn language(&self) -> &Language {
//         &C_LANG
//     }
//     type CreateProjectError = io::Error;
//     fn create_project(&self, path: &Path) -> Result<(), Self::CreateProjectError> {
//         let appname = path
//             .file_name()
//             .map(|s| s.to_str())
//             .flatten()
//             .unwrap_or("app");

//         let srcdir = path.join("src");
//         let builddir = path.join("build");

//         std::fs::create_dir_all(&srcdir)?;
//         std::fs::create_dir_all(&builddir)?;

//         std::fs::write(srcdir.join("prelude.h"), PRELUDE_H.as_bytes())?;
//         std::fs::write(srcdir.join("main.c"), MAIN_C.as_bytes())?;
//         std::fs::write(path.join("build.sh"), BUILDSCRIPT.as_bytes())?;

//         println!("Created C project {} in {}", appname, path.display());

//         Ok(())
//     }
// }

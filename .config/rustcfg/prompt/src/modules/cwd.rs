use crate::prelude::*;

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Git {
    pub repo_name: String,
    pub top_level: PathBuf,
}
impl Git {
    pub fn detect_git_repo(current_dir: &Path) -> io::Result<Self> {
        let mut cwd = current_dir;

        while let Some(parent) = cwd.parent() {
            cwd = parent;
            if let Some(git) = parent
                .read_dir()?
                .filter_map(|p| p.ok())
                .filter_map(|p| {
                    let file_name = p.file_name();
                    let file_str = file_name.to_string_lossy();
                    if file_str == ".git" {
                        let top_level = p.path();
                        if top_level.is_dir() {
                            return Some(Self {
                                repo_name: file_str.to_string(),
                                top_level,
                            });
                        }
                    }
                    None
                })
                .next()
            {
                return Ok(git);
            }
        }

        Err(io::ErrorKind::NotFound.into())
    }
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Cwd {
    pub git: Option<crate::modules::cwd::Git>,
    pub is_link: bool,
    pub cwd_display: String,
    pub hashed_dirs: HashMap<String, PathBuf>,
}
// impl Module for Cwd {
//     fn render(&self, config: crate::config::PrecmdConfig) -> String {

//     }
// }

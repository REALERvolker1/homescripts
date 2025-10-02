use ::std::path::{Path, PathBuf};

crate::choice_string_array! {
    strat: [
        RELATIVE = "--relative",
        AS_SPECIFIED = "--as-specified",
        ABSOLUTE = "--absolute",
    ]
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub enum ResolverStrategy {
    Relative = 0,
    #[default]
    AsSpecified = 1,
    Absolute = 2,
}
impl ResolverStrategy {
    pub fn resolve_path(self, link_path: &Path, destination: &Path) -> Option<PathBuf> {
        match self {
            Self::Absolute => destination.canonicalize().ok(),
            Self::AsSpecified => Some(destination.to_path_buf()),
            Self::Relative => pathdiff::diff_paths(destination, link_path),
        }
    }
}

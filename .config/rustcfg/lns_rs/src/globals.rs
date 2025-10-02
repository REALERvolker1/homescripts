use {
    crate::{formatting::ColorContext, resolver::ResolverStrategy},
    ::std::path::PathBuf,
};

pub struct Context {
    pub cwd: PathBuf,
    pub formatter: ColorContext,
    pub operations: Vec<Operation>,
}
impl Context {
    pub fn new() -> Self {
        let cwd = std::env::current_dir()
            .expect("No CWD! (did your current working directory get deleted?)");

        let cwd = if cwd.is_relative() {
            let canonical = cwd.canonicalize().unwrap_or(cwd);
            canonical
        } else {
            cwd
        };

        Self {
            cwd,
            formatter: ColorContext::NoColor,
            operations: Vec::new(),
        }
    }
    pub fn with_formatter(mut self, formatter: ColorContext) -> Self {
        self.formatter = formatter;
        self
    }
    pub fn push_operation(&mut self, operation: Operation) {
        self.operations.push(operation);
    }
}

#[derive(Debug, Clone, Copy)]
pub enum OpState {
    Clear,
    NeedsTarget,
    Ready,
}

#[derive(Debug, Default)]
pub struct Operation {
    pub dst: PathBuf,
    pub target: PathBuf,
    pub strategy: ResolverStrategy,
}
impl Operation {
    pub fn get_state(&self) -> OpState {
        if self.dst.as_os_str().is_empty() {
            OpState::Clear
        } else if self.target.as_os_str().is_empty() {
            OpState::NeedsTarget
        } else {
            OpState::Ready
        }
    }
    pub fn insert_next_path_arg(
        &mut self,
        ctx: &Context,
        path: PathBuf,
    ) -> Result<(), PathResolveError> {
        match self.get_state() {
            OpState::Clear => match self.strategy {
                ResolverStrategy::Absolute => {
                    self.dst = path
                        .canonicalize()
                        .map_err(PathResolveError::AbsoluteDestPathError)?
                }
                ResolverStrategy::AsSpecified => self.dst = path,
                ResolverStrategy::Relative => self.dst = path,
            },
            OpState::NeedsTarget => match self.strategy {
                ResolverStrategy::Absolute => self.target = path,
                ResolverStrategy::AsSpecified => self.target = path,
                ResolverStrategy::Relative => {
                    self.target = path;
                    self.dst = ResolverStrategy::Relative
                        .resolve_path(&self.target, &self.dst)
                        .ok_or_else(|| PathResolveError::RelativeDestPathError(self.dst.clone()))?
                }
            },
            OpState::Ready => return Err(path),
        }

        Ok(())
    }
    pub fn set_strategy(&mut self, strategy: ResolverStrategy) {
        self.strategy = strategy;
    }
}

#[derive(Debug, derive_more::Display)]
pub enum PathResolveError {
    #[display("Failed to get absolute path of {}", _0)]
    AbsoluteDestPathError(std::io::Error),
    #[display("Failed to resolve a relative path to {}", _0.display())]
    RelativeDestPathError(PathBuf),
    #[display("Link target path traverses directories that do not exist: {}", _0.display())]
    PathDestParentDirDoesNotExist(PathBuf),
}
impl std::error::Error for PathResolveError {}

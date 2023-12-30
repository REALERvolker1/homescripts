use ahash;
use std::{env, path::*};

// pub type Ansi = &'static str;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyntaxType {
    None,
    SingleDash,
    SinglePlus,
    DoubleDash,
    DoublePlus,
    SingleQuote,
    DoubleQuote,
    Alias,
    GlobalAlias,
    cufffixAlias,
    Builtin,
    Command,
    Function,
    Widget,
    Resword,
    NamedDir,
    UserDir,
    Directory,
    File,
    Variable,
    Prefix,
    Bracket,
    // TODO: Add more
}

/// Configuration for the current theme
#[derive(Debug, Clone)]
pub struct Theme {
    pub name: String,
    pub path: PathBuf,
    pub description: String,
    pub aliases
}

impl Theme {
    /// Read a theme from a file
    pub fn load(filepath: &Path) -> Self {
        // <P: AsRef<Path>> if needed
        Self {
            name,
            path,
            description,
        }
    }
}

use ahash;
use regex;
use std::{env, path, rc::Rc};

// mod config;

/// A very rough prototype of a zsh syntax highlighter
///
/// I got overwhelmed trying to implement everything so this is basic for now.
fn main() {
    let input_string = env::args().skip(1).next().unwrap();

    let mut syntax = Vec::new();

    let mut last: Token = ("", SyntaxType::None);
    for i in input_string.split(" ") {}

    // let mut syntax_tree = ahash::HashMap::new();
    // regex::Regex::new("(^| )")

    println!("{}", syntax);
}

pub type Color = &'static str;
pub type Token<'a> = (&'a str, SyntaxType);

#[derive(Debug, Clone)]
pub struct Config {
    builtin: Syntax,
    resword: Syntax,
    command: Syntax,
    function: Syntax,
    alias: Syntax,
    brace: Syntax,
    variable: Syntax,
    none: Syntax,
}

#[derive(Debug, Clone)]
pub struct Syntax {
    pub color: Color,
    pub syntax_type: SyntaxType,
    pub regex: Rc<regex::Regex>,
}
impl Default for Syntax {
    fn default() -> Self {
        Self {
            color: "",
            syntax_type: SyntaxType::None,
        }
    }
}

/// All the supported syntax types
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum SyntaxType {
    Builtin,
    Resword,
    Command,
    Function,
    Alias,
    Brace,
    Variable,
    #[default]
    None,
}
impl SyntaxType {
    /// Returns an iterator over all the supported syntax types
    pub fn iterator() -> impl Iterator<Item = Self> {
        // thank you https://stackoverflow.com/questions/21371534/in-rust-is-there-a-way-to-iterate-through-the-values-of-an-enum
        [
            Self::Builtin,
            Self::Resword,
            Self::Command,
            Self::Function,
            Self::Alias,
            Self::Brace,
            Self::Variable,
            Self::None,
        ]
        .iter()
        .copied()
    }
    pub fn regex(&self) -> regex::Regex {
        match self {
            Self::Builtin
            Self::Resword
            Self::Command
            Self::Function
            Self::Alias
            Self::Brace
            Self::Variable
            Self::None
        }
    }
}

pub const DEFAULT_CONFIG: Config = Config {
    builtin: "4;96",
    resword: "96",
    command: "1;92",
    function: "92",
    alias: "32",
    brace: "93",
};

// const FUNCTION: &str = "1;92";

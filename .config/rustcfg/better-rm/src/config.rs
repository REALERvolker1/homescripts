use std::io::IsTerminal;

use crate::prelude::*;

#[derive(Debug, Parser)]
#[command(author, version, about, long_about = None)]
pub struct Args {
    #[arg(help = "Paths to remove", required = true, value_hint = clap::ValueHint::AnyPath, trailing_var_arg = true)]
    pub provided_paths: Vec<PathBuf>,
    #[arg(skip)]
    pub sendable_paths: Vec<Arc<PathBuf>>,
    #[arg(
        long,
        help = "Prompt the user",
        long_help = "Choose when to prompt the user. If 'auto', it will prompt if called interactively.",
        default_value_t = InteractiveType::default()
    )]
    pub interactive: InteractiveType,
    #[arg(
        long,
        help = "The kind of prompt to use",
        long_help = "The kind of prompt to use. If the terminal is not interactive, it will default to 'action'",
        default_value_t = PromptType::default()
    )]
    pub prompt: PromptType,
    #[arg(
        short,
        long,
        help = "Show color",
        long_help = "When to show colors. It will show colors if called interactively.",
        default_value_t = ColorType::default()
    )]
    pub color: ColorType,
    #[arg(skip)]
    pub is_colored: bool,
    #[arg(skip)]
    pub is_terminal: bool,
    #[arg(
        short,
        long,
        help = "Force remove",
        long_help = "set action to 'delete', interactive to 'never'. Kept for rm compatibility.",
        default_value_t = false
    )]
    pub force: bool,
    #[arg(short = 'r', help = "Ignored for rm compatibility")]
    pub ignore_me_recursive: bool,
    #[arg(
        short,
        long,
        help = "The action to take",
        long_help = "Choose the default action to take. If the terminal is interactive, this is ignored in favor of 'prompt'.",
        default_value_t = ActionType::default()
    )]
    pub action: ActionType,
}
impl Args {
    pub fn new() -> Res<Self> {
        let mut cfg = Args::parse();

        if cfg.provided_paths.is_empty() {
            bail!(
                "No paths given! Please run {} --help",
                env!("CARGO_PKG_NAME")
            );
        }

        let protected_paths = protected_paths();
        let config_paths = std::mem::take(&mut cfg.provided_paths);
        for path in config_paths.into_iter() {
            // protected_paths should be pretty small
            if protected_paths.contains(&path) {
                bail!("Cannot remove protected path: {}", path.display());
            }

            cfg.sendable_paths.push(Arc::new(path))
        }
        let is_term = is_terminal();
        cfg.is_terminal = is_term;

        if cfg.color == ColorType::Auto {
            cfg.is_colored = is_term;
        }

        if cfg.force {
            cfg.action = ActionType::Delete;
            cfg.interactive = InteractiveType::Never;
        }

        Ok(cfg)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum, strum_macros::Display)]
#[clap(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum InteractiveType {
    /// Never prompt
    Never,
    /// Only prompt once
    Once,
    /// Always prompt
    Always,
}

impl Default for InteractiveType {
    fn default() -> Self {
        if is_terminal() {
            InteractiveType::Always
        } else {
            InteractiveType::Never
        }
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, ValueEnum, strum_macros::Display)]
#[clap(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum PromptType {
    /// A short prompt
    Short,
    /// A long prompt, including much more information about the paths
    #[default]
    Verbose,
}
impl PromptType {
    pub fn prompt(&self, input: PromptInput) -> Res<PromptInput> {
        let input_ref = &input;
        match input_ref {
            PromptInput::Always(path) => match self {
                Self::Short => print!("{}{TRASH_ASK}", path.display_minimal()),
                Self::Verbose => print!("{path}{TRASH_ASK}"),
            },
            PromptInput::Once(paths) => {
                let paths_str = match self {
                    Self::Short => paths
                        .iter()
                        .map(|p| p.display_minimal())
                        .collect::<Vec<_>>()
                        .join("\n"),
                    Self::Verbose => paths
                        .iter()
                        .map(|p| p.to_string())
                        .collect::<Vec<_>>()
                        .join("\n"),
                };

                print!("{paths_str}{TRASH_ASK}")
            }
        }

        // needed because rust only flushes stdout in lines
        io::stdout().flush()?;

        let mut stdin_input = String::new();
        io::stdin().read_line(&mut stdin_input)?;
        // print a newline
        println!();

        let chosen_action = match stdin_input.trim() {
            "t" | "T" => ActionType::Trash,
            "d" | "D" => ActionType::Delete,
            _ => ActionType::Skip,
        };

        Ok(input.set_action(chosen_action))
    }
}
const TRASH_ASK: &'static str = "\nTrash or Delete? [T/d] > ";

pub enum PromptInput {
    Always(crate::format::FormattedPath),
    Once(Vec<crate::format::FormattedPath>),
}
impl PromptInput {
    pub fn set_action(self, action: ActionType) -> Self {
        match self {
            PromptInput::Always(p) => Self::Always(p.set_action(action)),
            PromptInput::Once(p) => {
                Self::Once(p.into_iter().map(|p| p.set_action(action)).collect())
            }
        }
    }
    /// This function only works when this type is Always. It will panic otherwise.
    pub fn unwrap_always(self) -> crate::format::FormattedPath {
        match self {
            PromptInput::Always(p) => p,
            _ => unreachable!(),
        }
    }
    /// This function is just [`PromptInput::unwrap_always`] but for Once.
    pub fn unwrap_once(self) -> Vec<crate::format::FormattedPath> {
        match self {
            PromptInput::Once(p) => p,
            _ => unreachable!(),
        }
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, ValueEnum, strum_macros::Display)]
#[clap(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum ColorType {
    /// Always show colors
    Always,
    /// Only show colors if output is a terminal
    #[default]
    Auto,
    /// Never show colors
    Never,
}

pub fn is_terminal() -> bool {
    io::stdout().is_terminal() && io::stdin().is_terminal() && io::stderr().is_terminal()
}
pub fn term_size() -> (terminal_size::Width, terminal_size::Height) {
    terminal_size::terminal_size().unwrap_or((terminal_size::Width(80), terminal_size::Height(24)))
}

/// Retrieve a list of filepaths that are protected. This program will not allow you to delete them.
pub fn protected_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();

    // sudo rm -rf /*
    let slash = Path::new("/");
    paths.push(slash.to_path_buf());

    let slash_asterisk = slash
        .read_dir()
        .unwrap()
        .filter_map(|d| d.ok())
        .map(|d| d.path());
    paths.extend(slash_asterisk);

    if let Ok(h) = env::var("HOME") {
        paths.push(h.into());
    }

    paths
}

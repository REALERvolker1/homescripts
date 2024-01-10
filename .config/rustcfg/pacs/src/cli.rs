use termion::is_tty;
#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    strum_macros::Display,
    strum_macros::EnumString,
    strum_macros::EnumIter,
    clap::ValueEnum,
)]
#[strum(serialize_all = "kebab-case")]
pub enum QueryType {
    /// The CLI query type (Default for non-interactive use)
    CommandLine,
    /// Search for packages with an interactive prompt (Default for interactive TTYs)
    Interactive,
}
impl Default for QueryType {
    fn default() -> Self {
        if is_tty(&std::io::stdout()) {
            QueryType::Interactive
        } else {
            QueryType::CommandLine
        }
    }
}

#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Default,
    strum_macros::Display,
    strum_macros::EnumString,
    strum_macros::EnumIter,
    clap::ValueEnum,
)]
#[strum(serialize_all = "kebab-case")]
pub enum SearchBy {
    /// Search packages by name
    #[default]
    Name,
    /// Search including name and description
    NameDesc,
    /// Search packages providing files
    File,
    /// Search packages through their `provides` field
    Provides,
}

#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Default,
    strum_macros::Display,
    strum_macros::EnumString,
    strum_macros::EnumIter,
    clap::ValueEnum,
)]
#[strum(serialize_all = "kebab-case")]
pub enum Filter {
    /// Show all packages
    #[default]
    All,
    /// Only show packages installed
    Installed,
    /// Only show packages that aren't installed
    Available,
    /// Show all, excluding out-of-date packages
    Updated,
}

#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Default,
    strum_macros::Display,
    strum_macros::EnumString,
    strum_macros::EnumIter,
    clap::ValueEnum,
)]
#[strum(serialize_all = "kebab-case")]
pub enum ShowFrom {
    /// Only show packages from the pacman (alpm) sources
    #[default]
    Pacman,
    /// Only show packages from the AUR
    Aur,
    /// Show packages from all sources
    All,
}
impl ShowFrom {
    /// Returns true if it includes Arch packages
    #[inline]
    pub fn is_alpm(&self) -> bool {
        self != &Self::Aur
    }
    /// Returns true if it includes AUR packages
    #[inline]
    pub fn is_aur(&self) -> bool {
        self != &Self::Pacman
    }
}

#[derive(clap::Parser, Debug)]
#[command(author, version, about, long_about = None, arg_required_else_help(false))]
pub struct Args {
    #[arg(
        long,
        required = false,
        short = 'q',
        help = "Your search queries (use -q multiple times for multiple queries)"
    )]
    pub query: Vec<String>,
    // #[arg(
    //     long,
    //     short,
    //     default_value_t = false,
    //     help = "Include AUR packages in results"
    // )]
    // pub aur: bool,
    #[arg(long, short, default_value_t = Filter::default(), help = "Which packages to include in results")]
    pub filter: Filter,
    #[arg(long, default_value_t = QueryType::default(), help = "The query preset to use")]
    pub query_type: QueryType,
    #[arg(long, default_value_t = SearchBy::default(), help = "The search fields to use")]
    pub search_fields: SearchBy,
    #[arg(long, default_value_t = ShowFrom::default(), help = "The package sources to search from")]
    pub show_from: ShowFrom,
    #[arg(long, default_value_t = false, help = "Show debug logs")]
    pub debug: bool,
}

// #[derive(clap::Subcommand, Debug)]
// pub enum CommandLine {
//     #[command(arg_required_else_help = true)]
//     RE,
// }

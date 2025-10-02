use {
    crate::{
        formatting::{ColorContext, colorwhen},
        globals::{Context, Operation},
        resolver::{ResolverStrategy, strat},
    },
    ::core::{cell::Cell, fmt::Display},
    ::std::{
        ffi::OsString,
        fs::Metadata,
        io::Result as IoResult,
        path::{Path, PathBuf},
    },
};

pub fn parse_args() -> Context {
    let mut ctx = Context::new();

    let mut args = std::env::args_os();
    let argzero = args.next().expect(
        "First argument must be the command name! (Did your OS launch this process incorrectly?)",
    );

    let mut current_op = Operation::default();

    while let Some(arg) = args.next() {
        match arg.to_str() {
            Some(colorwhen::ALWAYS) => ctx = ctx.with_formatter(ColorContext::new_color()),
            Some(colorwhen::AUTO) => ctx = ctx.with_formatter(ColorContext::autodetect()),
            Some(colorwhen::NEVER) => ctx = ctx.with_formatter(ColorContext::NoColor),

            Some(strat::ABSOLUTE) => current_op.set_strategy(ResolverStrategy::Absolute),
            Some(strat::AS_SPECIFIED) => current_op.set_strategy(ResolverStrategy::AsSpecified),
            Some(strat::RELATIVE) => current_op.set_strategy(ResolverStrategy::Relative),

            _ => {
                match
            }
        }
    }

    ctx
}

const CLI_HELPTEXT: &str = const_format::concatcp![
    const_format::formatcp!("{} \t {}\n", colorwhen::ALWAYS, "Force ANSI color output"),
    const_format::formatcp!(
        "{} \t {}\n",
        colorwhen::AUTO,
        "Auto-detect ANSI color output, set the $NO_COLOR env var to disable color.",
    ),
    const_format::formatcp!("{} \t {}\n", colorwhen::NEVER, "Force no color output"),
    "\n\n",
    const_format::formatcp!(
        "{} \t {}\n",
        strat::ABSOLUTE,
        "Resolve all paths following this argument to absolute paths",
    ),
    const_format::formatcp!(
        "{} \t {}\n",
        strat::RELATIVE,
        "Resolve all link paths following this argument into destination-relative paths",
    ),
    const_format::formatcp!(
        "{} \t {}\n",
        strat::AS_SPECIFIED,
        "Do not do any path mangling. Use this if you need a special string for a symlink target.",
    ),
    "\n\n",
    "- Example 1: `",
    env!("CARGO_PKG_NAME"),
    " ",
    colorwhen::ALWAYS,
    " ",
    strat::ABSOLUTE,
    " ./foo.txt ./myfolder`\n",
    "This will create a link to the absolute path of `$PWD/foo.txt` at the path `$PWD/myfolder/foo.txt`. It will always print in color.\n",
    "- Example 2: `",
    env!("CARGO_PKG_NAME"),
    " ",
    strat::RELATIVE,
    " ./foo.txt ./myfolder`\n",
    "This will create a link with the destination of `../foo.txt` at the path `$PWD/myfolder/foo.txt`\n",
    "\nYou may pass as many jobs as you like."
];

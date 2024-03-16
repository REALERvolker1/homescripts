//! api here is kinda bad since I switched from using global arcmutex to using referenced hashmap. Sorry!

use ahash::HashMap;
use nix::unistd;
use nu_ansi_term::{Color, Style};
use once_cell::sync::Lazy;
use procfs::{
    process::{ProcState, StatFlags},
    ProcError, ProcResult,
};
use std::{path::PathBuf, rc::Rc};

use crate::CONFIG;

/// Interestingly enough, it is faster to have a single global LS_COLORS object than to create a new one for each thread.
pub static LS_COLORS: Lazy<lscolors::LsColors> =
    Lazy::new(|| lscolors::LsColors::from_env().unwrap_or_default());

static PROCESS_UID: Lazy<u32> = Lazy::new(|| unistd::Uid::current().as_raw());

pub fn format_process(process: &procfs::process::Process) -> ProcResult<String> {
    if !CONFIG.color {
        // I don't feel like adding all this compatibility right now.
        return if let Some(my_process) = Process::from_procfs_process(process, &mut None)? {
            Ok(my_process.format_for_fzf())
        } else {
            Err(ProcError::Other("Invalid process".to_owned()))
        };
    }

    let stat = process.stat()?;
    let status = process.status()?;

    let state = stat.state()?;
    let state_color = state_color(state);
    let owner_type = OwnerType::from_uid(process.uid()?).style();

    let flags = stat.flags()?;

    let uid = unistd::Uid::from_raw(status.euid);
    let username = match unistd::User::from_uid(uid) {
        Ok(Some(user)) => format!("{} ({})", user.name, user.uid),
        Ok(None) => uid.to_string() + " (unknown)",
        Err(e) => format!("Error getting user {}: {}", uid, e),
    };

    let flag_style = Color::LightYellow.reset_before_style().italic();

    Ok(format!(
        "Name: {} {}\nState: {}\nUser: {}\nArgs: {}\nFlags: [{}]\n",
        state_color.reset_before_style().bold().paint(status.name),
        owner_type.paint(format!("({})", stat.pid)),
        state_color.underline().paint(format!("{:?}", state)),
        owner_type.paint(username),
        format_process_args(process.cmdline().unwrap_or_default(), &mut None).join(" "),
        flags
            .iter_names()
            .map(|f| flag_style.paint(f.0).to_string())
            .collect::<Vec<_>>()
            .join(", "),
    ))
}

#[derive(Debug, PartialEq, Eq)]
pub struct Process {
    pub pid: i32,
    pub owner_type: OwnerType,
    pub state: ProcState,

    fmt_args: String,
    fmt_name: String,
    fmt_pid: String,
}
impl Process {
    pub fn from_procfs_process(
        process: &procfs::process::Process,
        cache: &mut PathColorCache,
    ) -> ProcResult<Option<Self>> {
        let stat = process.stat()?;

        let uid = process.uid()?;
        if CONFIG.mine && uid != *PROCESS_UID {
            return Ok(None);
        }
        let owner_type = OwnerType::from_uid(uid);

        let flags = stat.flags()?;

        if flags.contains(StatFlags::PF_KTHREAD) && !CONFIG.kernel_procs {
            return Ok(None);
        }

        let status = process.status()?;
        let state = stat.state()?;

        let fmt_args = if let Ok(a) = process.cmdline() {
            format_process_args(a, cache).join(" ")
        } else {
            String::new()
        };

        let fmt_name;
        let fmt_pid;

        // moving formatting from the print function to the constructor saves 4ms in debug mode because this is multithreaded.
        if CONFIG.color {
            fmt_name = state_color(state).paint(status.name).to_string();
            fmt_pid = owner_type.style().paint(stat.pid.to_string()).to_string();
        } else {
            fmt_name = status.name;
            fmt_pid = stat.pid.to_string();
        }

        let me = Self {
            pid: stat.pid,
            owner_type,
            state,
            fmt_args,
            fmt_name,
            fmt_pid,
        };

        // stat.cutime

        Ok(Some(me))
    }
    pub fn format_for_fzf(&self) -> String {
        // spaces between tabs just in case
        format!("{}\t{}\t{}", &self.fmt_pid, &self.fmt_name, &self.fmt_args)
    }
}

#[derive(Debug)]
pub struct FzfOutput(pub Vec<procfs::process::Process>);
impl FzfOutput {
    pub fn from_output(out: &str) -> ProcResult<Self> {
        let mut procs = Vec::new();
        for maybe_pid in out
            .split('\n')
            .filter_map(|p| p.split_once('\t')?.0.parse::<i32>().ok())
        {
            match procfs::process::Process::new(maybe_pid) {
                Ok(p) => procs.push(p),
                Err(e) => return Err(e),
            }
        }

        Ok(Self(procs))
    }
    /// Format each as a string, printing errors inline.
    #[inline]
    pub fn format_each(&self) -> Vec<String> {
        self.0
            .iter()
            .map(|p| format_process(p).unwrap_or_else(|e| e.to_string()))
            .collect()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum OwnerType {
    Mine,
    Others,
    Root,
}
impl OwnerType {
    pub fn from_uid(uid: u32) -> Self {
        if uid == unistd::ROOT.as_raw() {
            Self::Root
        } else if uid == *PROCESS_UID {
            Self::Mine
        } else {
            Self::Others
        }
    }
    #[inline]
    pub fn style(&self) -> Style {
        match self {
            Self::Mine => Color::LightGreen,
            Self::Others => Color::LightCyan,
            Self::Root => Color::LightRed,
        }
        .bold()
    }
}

pub const fn state_color(state: ProcState) -> Color {
    match state {
        ProcState::Running => Color::LightGreen,
        ProcState::Sleeping => Color::Yellow,
        ProcState::Waiting => Color::Cyan,
        ProcState::Idle => Color::LightYellow,

        ProcState::Tracing => Color::LightMagenta,
        ProcState::Stopped => Color::Magenta,
        ProcState::Dead => Color::LightRed,
        ProcState::Zombie => Color::Red,

        ProcState::Parked | ProcState::Wakekill | ProcState::Waking => Color::Blue, //old kernels
    }
}

static DEFAULT_ARG_STYLE: Lazy<Style> = Lazy::new(|| Style::new().fg(Color::Green));
static FLATPAK_RELATIVE_PATH_COLOR: Lazy<Style> = Lazy::new(|| Style::new().fg(Color::Cyan));

fn format_process_args(args: Vec<String>, cache: &mut PathColorCache) -> Vec<String> {
    // I split args on spaces because some chromium and electron apps don't split args on spaces and have one giant arg.
    // I also trim newlines and tabs and escapes and whatnot because those can break output.
    // I found negligible performance benefits to making this a parallel iter.
    if CONFIG.color {
        args.into_iter()
            .map(|a| a.replace(['\n', '\t', '\x1b', '\0', '\r'], " "))
            .flat_map(|a| {
                a.split(' ')
                    .map(|a| colorize_arg(a, cache))
                    .collect::<Vec<_>>()
            })
            .collect::<Vec<_>>()
    } else {
        args
    }
}

/// Colorize a program's argument.
///
/// This is not cached because it is used in a hot loop and the colorize functions are quick enough.
fn colorize_arg(maybe_path: &str, cache: &mut PathColorCache) -> String {
    let maybe_path = maybe_path.trim();
    if maybe_path.is_empty() {
        return maybe_path.to_owned();
    }

    let Some(find) = maybe_path.find('/') else {
        return DEFAULT_ARG_STYLE.paint(maybe_path).to_string();
    };

    let (prefix, probably_path) = maybe_path.split_at(find);

    let colorized_path = colorize_path(probably_path, cache);

    format!("{}{colorized_path}", DEFAULT_ARG_STYLE.paint(prefix))
}

/// I added this on really late so the code is definitely not designed around this lmao
pub type PathColorCache = Option<HashMap<String, Rc<String>>>;

// static COLORIZED_PATH_CACHE: Lazy<RwLock<HashMap<String, Arc<String>>>> =
//     Lazy::new(|| RwLock::new(HashMap::new()));

/// Colorize a path with ls colors. This is cached because the clone cost is probably less than the io cost.
fn colorize_path(pathlike: &str, cache: &mut PathColorCache) -> Rc<String> {
    if let Some(cache) = cache {
        if let Some(c) = cache.get(pathlike) {
            return Rc::clone(c);
        }
    }

    let pathlike_string = pathlike.to_owned();

    if pathlike.starts_with("/app") {
        let pack_string = Rc::new(FLATPAK_RELATIVE_PATH_COLOR.paint(pathlike).to_string());
        if let Some(cache) = cache {
            cache.insert(pathlike_string, Rc::clone(&pack_string));
        }
        return pack_string;
    }

    let pathlike = PathBuf::from(pathlike);

    let components = LS_COLORS.style_for_path_components(&pathlike);

    let comp_string = components
        .map(|(p, c)| {
            match c {
                Some(c) => c.to_nu_ansi_term_style().paint(p.to_string_lossy()),
                None => DEFAULT_ARG_STYLE.paint(p.to_string_lossy()),
            }
            .hyperlink(&pathlike_string)
            .to_string()
        })
        .collect::<Vec<_>>()
        .join("");

    let comp_string = Rc::new(comp_string);

    if let Some(cache) = cache {
        cache.insert(pathlike_string, Rc::clone(&comp_string));
    }

    comp_string
}

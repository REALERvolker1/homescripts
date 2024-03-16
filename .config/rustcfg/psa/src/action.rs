use nix::{
    sys::signal::{self, Signal},
    unistd::Pid,
};

use std::{
    io::{self, Write},
    process,
};

use crate::CONFIG;

#[derive(Debug, Default, PartialEq, Eq, Clone, Copy)]
pub enum Action {
    Menu,
    Pidstat,

    KillInterrupt,
    KillTerminate,
    KillHard,

    #[default]
    Ask,
}
impl Action {
    fn match_num(num: char) -> Self {
        match num {
            '1' => Self::Menu,
            '2' => Self::Pidstat,
            '3' => Self::KillInterrupt,
            '4' => Self::KillTerminate,
            '5' => Self::KillHard,
            _ => Self::Ask,
        }
    }
    const MESSAGES: [&'static str; 5] = [
        "1. Return to the main menu",
        "2. Run the `pidstat` command",
        "3. Kill the selected process(es) using SIGINT, or Ctrl-C (recommended)",
        "4. Kill the selected process(es) using SIGTERM",
        "5. Force-kill the selected process(es) instantly (Not recommended)",
    ];
    pub fn act(&self, processes: crate::proc::FzfOutput) -> procfs::ProcResult<()> {
        macro_rules! kill_proc {
            ($signal:ident) => {{
                let s = processes
                    .0
                    .into_iter()
                    .map(|p| {
                        let pid = p.pid();
                        let signal = Signal::$signal;
                        // double new line separate each output for readability.
                        // I append to this string because then I can just call .join("\n\n")
                        let mut out = format!("Killing process {pid} with {signal}\n");

                        if let Err(e) = signal::kill(Pid::from_raw(pid), signal) {
                            out += &format!("Failed to {signal} process {pid}: {e}");
                        }
                        out
                    })
                    .collect::<Vec<_>>()
                    .join("\n\n");

                eprintln!("{s}");
                Ok(())
            }};
        }
        match self {
            Self::Ask => {
                // use different scope to drop some values before doing the action
                let act = {
                    let stdin = Action::MESSAGES.into_iter().map(|s| s.to_owned()).collect();

                    let sel = CONFIG.pipe_command.exec(stdin)?;

                    // The exec function just exits the process if no selection is made. I know the char exists.
                    let number = sel.chars().next().unwrap();

                    Ok::<_, io::Error>(Self::match_num(number))
                }?;
                act.act(processes)
            }
            Self::Menu => {
                // Drop the processes as each one has file descriptors open
                std::mem::drop(processes);

                let new_processes = crate::menu()?;
                Self::Ask.act(new_processes)
            }
            Self::Pidstat => {
                let output = processes
                    .0
                    .into_iter()
                    .map(|p| {
                        match process::Command::new("pidstat")
                            .args(["-p", &p.pid().to_string()])
                            .env("S_COLORS", "always")
                            .output()
                        {
                            Ok(o) => String::from_utf8_lossy(&o.stdout).to_string(),
                            Err(e) => e.to_string(),
                        }
                    })
                    .collect::<Vec<_>>()
                    .join("\n\n");

                eprintln!("{output}");
                Ok(())
            }
            Self::KillInterrupt => kill_proc!(SIGINT),
            Self::KillTerminate => kill_proc!(SIGTERM),
            Self::KillHard => kill_proc!(SIGKILL),
        }
    }
}

/// Making my arg parser a declarative macro and my help text a const &'static str was a huge mistake.
pub const DEFAULT_SELECTOR_COMMAND_STRING: &str = "fzf --multi --ansi --preview-window=down,25%";

#[derive(Debug, PartialEq, Eq)]
pub struct SelectorCommand {
    pub bin: String,
    pub args: Vec<String>,
}
impl Default for SelectorCommand {
    fn default() -> Self {
        Self::new(DEFAULT_SELECTOR_COMMAND_STRING).unwrap()
    }
}
impl SelectorCommand {
    pub fn new(cmd: &str) -> Option<Self> {
        let mut comm = cmd.trim().split(' ').map(|s| s.to_owned());

        Some(Self {
            bin: comm.next()?,
            args: comm.collect(),
        })
    }
    pub fn as_string(&self) -> String {
        let mut args = self.args.clone();
        args.insert(0, self.bin.clone());
        args.join(" ")
    }
    pub fn exec(&self, stdin_input: Vec<String>) -> io::Result<String> {
        let mut proc = process::Command::new(&self.bin)
            .args(&self.args)
            .stdin(process::Stdio::piped())
            .stdout(process::Stdio::piped())
            .spawn()?;

        if let Some(stdin) = proc.stdin.as_mut() {
            for s in stdin_input {
                writeln!(stdin, "{s}")?;
            }
        }

        let output = proc.wait_with_output()?;

        let out = String::from_utf8_lossy(output.stdout.as_slice());

        // nothing selected, user probably hit esc
        if out.is_empty() {
            eprintln!("No process selected!");
            std::process::exit(0);
        }

        Ok(out.trim().into())
    }
}

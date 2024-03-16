/// A function to get the terminal width for the preferred width. If it cannot get the terminal width, then it will return usize::MAX, basically disabling it anyways.
pub fn terminal_width() -> usize {
    let size_cmd_output = process::Command::new("tput").arg("cols").output();

    if let Ok(size_cmd) = size_cmd_output {
        let stdout = String::from_utf8_lossy(&size_cmd.stdout);
        if let Ok(cols) = stdout.trim().parse::<usize>() {
            cols
        } else {
            usize::MAX
        }
    } else {
        usize::MAX
    }
}

// This is intended to make it so the args cut off at a somewhat reasonable width.
// It will not be the full width, but ehh idc
// let preferred_width_base = command::terminal_width();

#[derive(Debug, Clone, Copy)]
pub struct CapabilitySet {
    full_stats: AvailableOptions,
    pretty_print: AvailableOptions,
    pidstat: Option<AvailableOptions>,
    proc_tree: AvailableOptions,
    kill: AvailableOptions,
    kill_sudo: Option<AvailableOptions>,
}
impl Default for CapabilitySet {
    fn default() -> Self {
        Self {
            full_stats: None,
            pretty_print: None,
            pidstat: AvailableOptions::PidStat,
            proc_tree: AvailableOptions::PidStat,
            kill: AvailableOptions::PidStat,
            kill_sudo: AvailableOptions::PidStat,
        }
    }
}
impl CapabilitySet {
    pub fn get_capabilities() -> Self {
        let mut capabilities = Self::default();
        // These require external dependencies
        if let Ok(cmds) = command::check_dependencies(&["pidstat", "sudo"]) {
            for cmd in cmds {
                let cap = match cmd.as_str() {
                    "pidstat" => capabilities.pidstat = Some(AvailableOptions::PidStat),
                    "sudo" => capabilities.kill_sudo = Some(AvailableOptions::KillSudo),
                };
            }
        }
        capabilities
    }
}

// let mut args_style = Vec::new();
// // I am styling these all here just so there is less duplicated work and computation. I don't need the bare args.
// // Make sure I don't overflow the terminal with tons of args if I don't have to.
// let mut line_length = 0;
// for arg in args_iter {
//     if line_length < approximate_preferred_width {
//         // arg.chars.count() is a O(n) operation, but it works on unicode.
//         let arg_length = arg.chars().count();
//         args_style.push(style_cache.get_styled_arg(arg));
//         line_length = line_length + arg_length;
//     }
// }

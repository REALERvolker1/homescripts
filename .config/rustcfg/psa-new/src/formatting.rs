use crate::processes::ProcInfoCache;
use crate::*;
use nu_ansi_term::AnsiGenericString;
use unicode_width::UnicodeWidthStr;

pub fn proc_tree(current_pid: Pid, process_cache: &ProcInfoCache) -> String {
    let current = if let Some(c) = process_cache.get(current_pid) {
        c
    } else {
        return "Could not find process".into();
    };

    // the default styles
    let parent_style = Color::LightMagenta.bold();
    let child_style = Color::Green.bold();
    let current_style = Color::LightYellow.bold();

    let current_pid = current.pid();

    let child_processes = process_cache
        .processes
        .values()
        .filter(|p| p.ppid() == current_pid)
        .collect_vec();

    let mut previous_ppid: Pid = current.ppid();
    let mut parents = Vec::new();

    // get the parents
    while let Some(parent) = process_cache.get(previous_ppid) {
        previous_ppid = parent.ppid();
        parents.push(parent);

        // we don't need to get the next
        if previous_ppid == PID_NULL {
            break;
        }
    }

    // reverse the parent pid list, since that was calculated in reverse
    let mut process_tree = parents
        .into_iter()
        .rev()
        .enumerate()
        .map(|(i, p)| {
            let indentation = "  ".repeat(i);
            format!(
                "{indentation}╰─({}) {}",
                parent_style.paint(p.pid().to_string()),
                p.name()
            )
        })
        .collect_vec();

    let num_parents = process_tree.len();

    // insert self
    process_tree.push(format!(
        "{}╰─({}) {}",
        "  ".repeat(process_tree.len()),
        current_style.paint(current_pid.to_string()),
        bold!(current.name())
    ));

    let num_child_procs = child_processes.len();

    // I don't need to append anything
    if num_child_procs == 0 {
        return process_tree.join("\n");
    }

    let indent_string = "  ".repeat(process_tree.len() + 1);

    process_tree.append(
        &mut child_processes
            .into_iter()
            .map(|p| {
                format!(
                    "{}├─({}) {}",
                    &indent_string,
                    child_style.paint(p.pid().to_string()),
                    p.name()
                )
            })
            .collect_vec(),
    );

    // Print the number of parent, and child processes to the end to make the box drawing characters line up nicely
    process_tree.push(
        bold!(format!(
            "{}╰─({}) parents, ({}) children",
            indent_string, num_parents, num_child_procs
        ))
        .to_string(),
    );

    process_tree.join("\n")
}

impl ProcessInfo {
    pub fn format_details(&self) -> String {
        String::new()
    }
}

/// Returns the string styled with the default color for args
macro_rules! arg_def {
    ($arg:expr) => {
        return Color::DarkGray.paint($arg).to_string()
    };
}

/// Format the args of a process into a string.
///
/// This is only required once for one specific use case, so it can only process one type of data.
pub fn format_argument(argument: &str) -> String {
    let slash_index = if let Some(s) = argument.find('/') {
        s
    } else {
        arg_def!(argument);
    };

    let (before, after) = argument.split_at(slash_index);

    format!("{before}{}", get_path_style(after.to_string()))
}

#[cached]
pub fn get_path_style(path: String) -> String {
    // if let Some(s) = LS_COLORS.style_for_path(&path) {
    //     s.to_nu_ansi_term_style().paint(path).to_string()
    // } else {
    //     arg_def!(path)
    // }
    let mut output = Vec::new();

    for potential_path in path.split('/') {
        output.push(if let Some(s) = LS_COLORS.style_for_path(potential_path) {
            s.to_nu_ansi_term_style().paint(&path).to_string()
        } else {
            arg_def!(path)
        })
    }
    output.join("")
}

use crate::{proc, procinfo};
use static_init::dynamic;
use std::rc::Rc;
// use lscolors::Color;
use nu_ansi_term::{self, Color, Style};

/// Helper macro to create styles. Be careful, as editing it does not update the macro in other files
// #[macro_export]
macro_rules! style {
    ($color:expr) => {
        Color::Fixed($color).reset_before_style()
    };
    ($color:expr, bold) => {
        Color::Fixed($color).reset_before_style().bold()
    };
}

pub struct ColorConfig {
    pub root_color: Style,
    pub user_color: Style,
    pub other_user_color: Style,
    pub unknown_user_color: Style,
    pub state_zombie_color: Style,
    pub state_running_color: Style,
    pub state_idle_color: Style,
    pub state_sleeping_color: Style,
    pub state_disksleep_color: Style,
    pub state_unknown_color: Style,
    pub args_color: Style,
}
impl Default for ColorConfig {
    fn default() -> Self {
        Self {
            root_color: style!(196, bold),
            user_color: style!(48, bold),
            other_user_color: style!(51),
            unknown_user_color: style!(196),
            state_zombie_color: style!(124, bold),
            state_running_color: style!(46, bold),
            state_idle_color: style!(190),
            state_sleeping_color: style!(184),
            state_disksleep_color: style!(172, bold),
            state_unknown_color: style!(196, bold),
            args_color: style!(34),
        }
    }
}

// lazy_static! {
//     pub static ref COLOR_CONFIG: ColorConfig = ColorConfig::default();
// }
#[dynamic]
pub static COLOR_CONFIG: ColorConfig = ColorConfig::default();

pub const DELIM: &str = "\t";

#[derive(Debug, Copy, Clone)]
enum ProcessTreeType {
    Parent,
    // Mine,
    // Child,
}
impl ProcessTreeType {
    fn format_name(&self, process_name: &str, pid: i32) -> String {
        // let (pid_style, name_style) = match self {
        //     Self::Mine => (style!(57, bold), style!(46, bold)),
        //     Self::Parent => (style!(202, bold), style!(154)),
        //     Self::Child => (style!(243, bold), style!(245)),
        // };
        let (pid_style, name_style) = (style!(202, bold), style!(154));
        format!(
            "({}) [{}]",
            pid_style.paint(pid.to_string()),
            name_style.paint(process_name)
        )
    }
}

/// prints the parents of a process.
pub fn print_process_tree(process: Rc<proc::Proc>) -> Result<(), procinfo::ProcError> {
    // TODO: If I ever have time, make this also get the children
    let mut tree_procs = Vec::new(); // collections::VecDeque
    println!("Process tree for {}\n", process.name_styled);

    // insert selected process
    tree_procs.push(format!(
        "({}) [{}]",
        process.pid_styled, process.name_styled
    ));
    {
        // Process parents
        let treetype = ProcessTreeType::Parent;
        // junk placeholder value
        let mut prev_ppid = process.ppid;
        loop {
            // while let Ok was not working
            if let Ok(parent) = proc::Proc::from_pid(prev_ppid) {
                if parent.ppid == prev_ppid {
                    break;
                } else {
                    tree_procs.push(treetype.format_name(&parent.name, parent.pid));
                    prev_ppid = parent.ppid;
                }
            } else {
                break;
            }
        }
    }

    let output = tree_procs
        .iter()
        .rev()
        .enumerate()
        .map(|(idx, s)| {
            let (pad, arm) = if idx > 0 {
                ("  ".repeat(idx - 1), "╰─")
            } else {
                ("".to_owned(), "")
            };
            format!("{}{}{}", pad, arm, s)
        })
        .collect::<Vec<_>>()
        .join("\n");

    println!("{}", output);
    Ok(())
}

#[test]
fn test_color_macro() {
    let color = style!(240);
    let ansi_color = Color::Fixed(240).reset_before_style();
    assert_eq!(color, ansi_color);
}

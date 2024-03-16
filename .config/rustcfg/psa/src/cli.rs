// implementing the macro

#[derive(Debug)]
pub struct Config {
    pub color: bool,
    pub kernel_procs: bool,
    pub mine: bool,
    pub pipe_command: crate::action::SelectorCommand,
    pub format_tab_delimited: Option<String>,
}
impl Default for Config {
    fn default() -> Self {
        Self {
            color: true,
            kernel_procs: false,
            mine: false,
            pipe_command: crate::action::SelectorCommand::default(),
            format_tab_delimited: None,
        }
    }
}
impl Config {
    pub fn new() -> Self {
        let mut me = Self::default();

        let mut args = std::env::args().skip(1);

        while let Some(arg) = args.next() {
            match arg.as_str() {
                "--color" => me.color = true,
                "--no-color" => me.color = false,

                "--kernel-procs" => me.kernel_procs = true,
                "--no-kernel-procs" => me.kernel_procs = false,

                "--mine" => me.mine = true,
                "--all" => me.mine = false,

                "--format-tab-delimited" => {
                    if let Some(a) = args.next() {
                        me.format_tab_delimited = Some(a);
                    } else {
                        Self::panic_help(&arg, "Missing value");
                    }
                }

                "--pipe-command" => {
                    if let Some(a) = args.next() {
                        if let Some(c) = crate::action::SelectorCommand::new(&a) {
                            me.pipe_command = c;
                        } else {
                            Self::panic_help(&arg, "Invalid value");
                        }
                    } else {
                        Self::panic_help(&arg, "Missing value");
                    }
                }
                _ => Self::panic_help(&arg, "Unknown option"),
            }
        }

        me
    }

    fn panic_help(arg: &str, error_message: &str) {
        let default = Self::default();

        eprintln!(
            "Usage: {} [OPTIONS]

--color             Show colored output (default)
--no-color          Don't show colored output

--kernel-procs      Show kernel processes along with regular system processes
--no-kernel-procs   Hide kernel processes (default)

--mine              Only show the current user's processes (default)
--all               Show processes belonging to anyone

--pipe-command  The command to run fzf with. Should be an fzf-compatible program.
    default: {}",
            env!("CARGO_PKG_NAME"),
            default.pipe_command.as_string()
        );
        panic!("{error_message}: {arg}")
    }
}

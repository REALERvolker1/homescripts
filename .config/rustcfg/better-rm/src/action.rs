use crate::prelude::*;

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, ValueEnum, strum_macros::Display)]
#[clap(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum ActionType {
    /// Send to the trash
    Trash,
    /// Delete forever (A really long time)
    Delete,
    /// Skip this file
    #[default]
    Skip,
}
pub fn act(paths: Vec<FormattedPath>) -> Res<()> {
    // I am only using one Vec here so that all events are in order
    let mut messages = Vec::new();

    eprintln!("Removing...");
    for path in paths.into_iter() {
        let print_type = match path.action {
            ActionType::Delete => {
                let pth = &*path.path;
                let res = if path.is_dir {
                    fs::remove_dir_all(pth)
                } else {
                    fs::remove_file(pth)
                };
                PrintType::from_result(res, path)
            }
            ActionType::Trash => PrintType::from_result(trash::delete(&*path.path), path),
            ActionType::Skip => PrintType::Error((eyre!("Skipped"), path)),
        };

        messages.push(print_type);
    }

    let mut stdout_lock = std::io::stdout().lock();
    let mut stderr_lock = std::io::stderr().lock();
    for msg in messages.into_iter() {
        let message_string = msg.to_string() + "\n";
        if msg.is_success() {
            stdout_lock.write_all(message_string.as_bytes())?;
        } else {
            stderr_lock.write_all(message_string.as_bytes())?;
        }
    }

    Ok(())
}

enum PrintType {
    Success(FormattedPath),
    Error((simple_eyre::Report, FormattedPath)),
}
impl PrintType {
    pub fn is_success(&self) -> bool {
        matches!(self, PrintType::Success(_))
    }
    pub fn from_result<E>(res: Result<(), E>, path: FormattedPath) -> Self
    where
        E: Into<simple_eyre::Report>,
    {
        match res {
            Ok(_) => PrintType::Success(path),
            Err(e) => PrintType::Error((e.into(), path)),
        }
    }
}
impl fmt::Display for PrintType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PrintType::Success(path) => {
                write!(f, "Success: {}: {}", path.action, path.display_minimal())
            }
            PrintType::Error((report, path)) => write!(
                f,
                "{}\nError: {}: {report}",
                path.display_minimal(),
                path.action,
            ),
        }
    }
}

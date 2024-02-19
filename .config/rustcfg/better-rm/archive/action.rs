use crate::{config, format::FormattedPath, prelude::*};
use std::{
    cmp::Ordering,
    io::Write,
    sync::{mpsc, Arc},
};

/// I think this is the amount where multithreading actually starts to make sense
const MIN_JOBS_PER_THREAD: usize = 8;

#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    ValueEnum,
    strum_macros::Display,
    strum_macros::AsRefStr,
    strum_macros::EnumString,
)]
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
    let mut recursive_paths = Vec::new();
    for path in paths.iter() {
        let recursive = path.walk_recursively()?;
        recursive_paths.extend(recursive);
    }

    // sort it all so directories are last
    recursive_paths.sort_unstable_by(|a, b| {
        let a_dir = a.1.is_dir() && !a.1.is_symlink();
        let b_dir = b.1.is_dir() && !b.1.is_symlink();
        if a_dir && !b_dir {
            Ordering::Greater
        } else if !a_dir && b_dir {
            Ordering::Less
        } else {
            Ordering::Equal
        }
    });

    // might as well make it a little (or a lot) faster
    let thread_count = if let Ok(t) = std::thread::available_parallelism() {
        let parallelism_count = t.get();
        let max_num_of_threads = recursive_paths.len() / MIN_JOBS_PER_THREAD;

        if max_num_of_threads > parallelism_count {
            // I don't want to overload the CPU here
            parallelism_count
        } else if max_num_of_threads == 0 {
            // I need at least 1 job
            1
        } else {
            max_num_of_threads
        }
    } else {
        1
    } - 1;

    let (tx, rx) = mpsc::channel();
    let mut handles = Vec::new();
    // enter a block here so that I can drop the sender and the recursive_paths ASAP
    {
        let sender = Arc::new(tx);
        let mut paths = recursive_paths.into_iter();

        if thread_count == 0 {
            thread_thingy(paths, sender)?;
        } else {
            // I do +1 here because my take method can handle nulls.
            let chunk_size = (paths.len() / thread_count) + 1;

            for id in 0..thread_count {
                let my_sender = Arc::clone(&sender);
                let mut my_paths = Vec::new();
                for _ in 0..chunk_size {
                    if let Some(p) = paths.next() {
                        my_paths.push(p);
                    } else {
                        break;
                    }
                }
                handles.push(std::thread::spawn(move || {
                    thread_thingy(my_paths.into_iter(), my_sender)
                }));
            }
        }
    }

    {
        let mut errors = Vec::new();
        {
            let mut stdout_lock = std::io::stdout().lock();

            while let Ok(result) = rx.recv() {
                match result {
                    Ok(msg) => {
                        let _ = stdout_lock.write((msg + "\n").as_bytes());
                    }
                    Err(e) => {
                        errors.push(format!("{}\n{}", e.0, e.1.display()));
                    }
                }
            }
            stdout_lock.flush()?;
        }

        let successful_thread_number = if handles.is_empty() {
            1
        } else {
            handles
                .into_iter()
                .filter_map(|h| match h.join() {
                    Ok(Ok(_)) => Some(()),
                    Ok(Err(e)) => {
                        errors.push(e.to_string());
                        None
                    }
                    Err(_) => {
                        errors.push("An error occured while joining a thread".to_owned());
                        None
                    }
                })
                .count()
        };

        errors.push(format!(
            "{successful_thread_number}/{thread_count} threads finished successfully"
        ));

        // it's safe to write now that all the good logs have been written
        let mut stderr_lock = std::io::stderr().lock();
        let error_string = errors.join("\n") + "\n";
        stderr_lock.write(error_string.as_bytes())?;
        stderr_lock.flush()?;
    }

    Ok(())
}

/// This is run on each thread
fn thread_thingy<I>(
    paths: I,
    sender: Arc<mpsc::Sender<Result<String, (simple_eyre::Report, PathBuf)>>>,
) -> Res<()>
where
    I: Iterator<Item = (ActionType, PathBuf)>,
{
    for (action, path) in paths {
        // I am using println! so that I don't have to lock these streams
        match action {
            ActionType::Delete => match rm(&path) {
                Ok(()) => sender.send(Ok(format!("Removed {}", &path.display()))),
                Err(e) => sender.send(Err((e, path))),
            },
            ActionType::Trash => match trash::delete(&path) {
                Ok(()) => sender.send(Ok(format!("Trashed {}", &path.display()))),
                Err(e) => sender.send(Err((e.into(), path))),
            },
            ActionType::Skip => sender.send(Err((eyre!("Skipped"), path))),
        }?
    }

    Ok(())
}

#[inline]
fn rm(path: &Path) -> Res<()> {
    if path.is_dir() {
        fs::remove_dir(path)?;
    } else {
        fs::remove_file(path)?;
    }
    Ok(())
}

// /// Could recursively take a shit ton of memory but at least this makes the parallelism balanced.
// ///
// /// If your system can't handle the memory demands, then the act of running this program is literally a skill issue.
// fn files_to_delete<I>(input_paths: I) -> Vec<PathBuf> where I: IntoIterator<Item = Path> {
//     walkdir::WalkDir::new(root)
// }

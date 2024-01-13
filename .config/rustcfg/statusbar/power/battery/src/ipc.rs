use crate::{types::ModError, *};
use nix::{sys::stat::Mode, unistd};
use std::{env, path::*};
use tracing::warn;

// lazy_static! {
//     pub static ref IPC: PathBuf = ;
// }

#[derive(Debug, Clone, Copy, PartialEq, Eq, strum_macros::Display, clap::ValueEnum)]
pub enum TmpDirType {
    /// The tempdir is XDG_RUNTIME_DIR
    XdgRuntimeDir,
    /// The tempdir is set to /tmp or similar
    Tmp,
    /// The tempdir is custom
    Custom,
}

/// The IPC interface for this. It is intended as a temporary measure while I
/// transition and test these modules on waybar before building the gtk app
#[derive(Debug)]
pub struct IpcInterface {
    pub tmpdir: PathBuf,
    pub recv_fifo: PathBuf,
    pub send_fifos: Vec<PathBuf>,
}
impl IpcInterface {
    /// Create a new IPC interface
    #[tracing::instrument]
    pub fn new(handler_count: usize) -> Result<Self, ModError> {
        let tmpdir = get_tmpdir().join(env!("CARGO_PKG_NAME"));
        let tmpdir_path = tmpdir.as_path();

        // we don't need to have multiple instances.
        // TODO: Add multi-instance detection
        if tmpdir_path.is_dir() {
            std::fs::remove_dir_all(tmpdir_path)?;
        }

        let recv_fifo = tmpdir_path.join(env!("CARGO_PKG_NAME"));
        // Panic here, because we can't initialize IPC if there is no receiving channel
        unistd::mkfifo(&recv_fifo, Mode::S_IRWXU).unwrap();

        let send_fifos = (1..handler_count)
            .into_iter()
            .map(|i| {
                let path = tmpdir_path.join(i.to_string() + ".fifo");
                // Panic if we can't initialize IPC. If we can't initialize it, what's the point?
                unistd::mkfifo(&path, Mode::S_IRWXU).unwrap();
                path
            })
            .map(|r| r)
            .collect();
        Ok(Self {
            tmpdir,
            recv_fifo,
            send_fifos,
        })
    }
}

#[tracing::instrument]
fn get_tmpdir<'a>() -> PathBuf {
    if let Ok(rt) = env::var("XDG_RUNTIME_DIR") {
        let env_path = Path::new(&rt);
        if let Ok(m) = env_path.metadata() {
            if !m.permissions().readonly() && m.is_dir() {
                // it is safe to use XDG_RUNTIME_DIR
                return env_path.to_path_buf();
            }
        }
    }
    warn!("XDG_RUNTIME_DIR is not set or not writable, falling back to system tempdir");
    env::temp_dir()
}

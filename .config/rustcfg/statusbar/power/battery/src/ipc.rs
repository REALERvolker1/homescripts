use crate::{types::*, *};
use lazy_static::lazy_static;
use nix::{sys::stat::Mode, unistd};
use serde::{Deserialize, Serialize};
use std::{env, path::*, sync::Arc};
use tokio::io::AsyncWriteExt;
use tracing::{error, warn};

lazy_static! {
    pub static ref TEMP_DIR: PathBuf = get_tmpdir().join(env!("CARGO_PKG_NAME"));
}

// pub type IpcType = std::sync::Arc<tokio::sync::Mutex<IpcInterface>>;

/// TODO: This is a piece of shit that doesn't work. Completely rewrite the ipc to use files similar to sysfs
///
///
/// The IPC interface for this. It is intended as a temporary measure while I
/// transition and test these modules on waybar before building the gtk app
#[derive(Debug, Default)]
pub struct IpcInterface {
    recv_fifo: PathBuf,
    send_fifos: Vec<Arc<PathBuf>>,
}

impl IpcInterface {
    /// Create a new IPC interface
    #[tracing::instrument]
    pub async fn new(handler_count: u8) -> Result<Self, ModError> {
        let tmpdir_path = TEMP_DIR.as_path();

        // we don't need to have multiple instances.
        // TODO: Add multi-instance detection
        if tmpdir_path.is_dir() {
            tokio::fs::remove_dir_all(tmpdir_path).await?;
        }

        tokio::fs::create_dir_all(tmpdir_path).await?;

        let recv_fifo = tmpdir_path.join("send.fifo");
        // unistd::mkfifo(&recv_fifo, Mode::S_IRWXU)?;

        let mut send_fifos = Vec::new();

        for i in 0..handler_count {
            let path = tmpdir_path.join(i.to_string() + ".fifo");
            unistd::mkfifo(&path, Mode::S_IRWXU)?;
            send_fifos.push(Arc::new(path));
        }

        Ok(Self {
            recv_fifo,
            send_fifos,
        })
    }
    /// Keep track of a new pipe
    ///
    /// This function will panic if it finds a duplicate module registered
    #[tracing::instrument]
    pub async fn new_pipe(&mut self, name: modules::ModuleName) -> Result<(), ModError> {
        let path = TEMP_DIR.join(name.to_string() + ".fifo");
        if path.exists() {
            panic!("Duplicate module registered: {name}");
        }
        unistd::mkfifo(&path, Mode::S_IRWXU)?;
        self.send_fifos.push(Arc::new(path));
        Ok(())
    }
    /// Send data to all the pipes
    ///
    /// This function will panic if it can't close the write handles, or if it can't join the subtasks
    #[tracing::instrument]
    pub async fn send(&self, input_message: &str) -> tokio::io::Result<()> {
        let mut streams = tokio::task::JoinSet::new();

        let arc_message: Arc<[u8]> = Arc::from((input_message.to_owned() + "\n").as_bytes());
        self.send_fifos.iter().for_each(|f| {
            // initialize owned values to be moved into the closure
            let my_message = Arc::clone(&arc_message);
            let me = Arc::clone(f);

            streams.spawn(async move {
                // This is the subtask for writing to the send fifos
                let file_task = tokio::fs::OpenOptions::new()
                    .append(true)
                    .open(me.as_path())
                    .await;

                if let Ok(mut file) = file_task {
                    let write_task = file.write_all(&my_message).await;

                    if let Err(w) = write_task {
                        error!("failed to write to fifo: {w}");
                    } else {
                        let close_task = file.shutdown().await;

                        if let Err(e) = close_task {
                            // If we can't close the fifo, this breaks everything
                            error!("failed to close fifo write handle: {e}");
                            panic!(
                                "(IPC interface) failed to properly close fifo write handle: {e}\nAt path {}", &me.to_string_lossy()
                            );
                        }
                    }
                } else {
                    error!("failed to open fifo: {}", &me.to_string_lossy());
                }
            });
        });

        while let Some(t) = streams.join_next().await {
            if let Err(e) = t {
                error!("failed to join stream: {e:?}");
                panic!("(IPC interface) failed to join subtask: {e:?}");
            }
        }
        Ok(())
    }
}

#[inline]
fn get_tmpdir() -> PathBuf {
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

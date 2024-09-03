mod argparse;
mod get_mice;

use hypesocket::hyprctl::{CtlFlag, HyprctlSocket};
use std::io;

const RELOAD_FLAG: CtlFlag = CtlFlag::Custom("r");
const JSON: Option<&[CtlFlag]> = Some(&[CtlFlag::Json]);

fn main() {
    if let Err(e) = main_wrapped() {
        eprintln!("[{e:?}] {e}");
        std::process::exit(e.exit_code());
    }
}

#[inline]
fn main_wrapped() -> Result<(), AppError> {
    let mut stdout = io::stdout().lock();
    crate::argparse::print_help(&mut stdout, None).unwrap();
    return Ok(());
    let args = crate::argparse::Args::parse()?;

    let mut ctlsock = HyprctlSocket::new_from_env().map_err(|e| AppError::InitCtlSock(e))?;

    let has_mice = crate::get_mice::query_data(&mut ctlsock, &mut stdout, &args)?;

    Ok(())
}

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("Failed to parse arguments: {0}")]
    ArgParse(#[from] crate::argparse::ArgParseError),
    #[error("Failed to initialize hyprctl socket: {0}")]
    InitCtlSock(io::Error),
    #[error("Failed to detect mice: {0}")]
    MouseDetect(#[from] crate::get_mice::MouseDetectError),
}
impl AppError {
    pub const fn exit_code(&self) -> i32 {
        match self {
            Self::ArgParse(_) => 12,
            Self::InitCtlSock(_) => 4,
            Self::MouseDetect(_) => 1,
        }
    }
}

use crate::*;
use nix::{libc, pty::Winsize};
use std::mem;

nix::ioctl_read_bad!(getwinsz, libc::TIOCGWINSZ, Winsize);

/// Get the size of the terminal
// #[must_use]
pub unsafe fn term_size() -> Bruh<Winsize> {
    let mut win_size = mem::MaybeUninit::<Winsize>::uninit();
    getwinsz(libc::STDOUT_FILENO, win_size.as_mut_ptr())?;
    let win_size = win_size.assume_init();
    Ok(win_size)
}

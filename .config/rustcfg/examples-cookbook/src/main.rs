mod gtk_responsive_futures_lite;
mod gtk_responsive_tokio;

fn main() {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async { gtk_responsive_tokio::example() });

    // get the terminal size using a memory-safe blazingly fast ioctl
    // use nix::{libc, pty::Winsize};
// nix::ioctl_read_bad!(getwinsz, libc::TIOCGWINSZ, Winsize);

// /// Get the size of the terminal
// // #[must_use]
// pub unsafe fn term_size() -> Bruh<Winsize> {
//     let mut win_size = mem::MaybeUninit::<Winsize>::uninit();
//     getwinsz(libc::STDOUT_FILENO, win_size.as_mut_ptr())?;
//     let win_size = win_size.assume_init();
//     Ok(win_size)
// }
}

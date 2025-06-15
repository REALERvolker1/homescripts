#![allow(static_mut_refs)]

use {
    crate::tui::TermRect,
    ::core::{
        ffi::{c_int, c_void},
        fmt::Debug,
        mem::MaybeUninit,
        sync::atomic::{AtomicBool, AtomicPtr, AtomicU32, Ordering},
    },
    ::std::{
        io,
        os::unix::prelude::AsRawFd,
        path::{Path, PathBuf},
        thread::{JoinHandle, Thread},
    },
    ::termion::screen::IntoAlternateScreen,
};

#[macro_export]
macro_rules! outstream {
    () => {
        ::std::io::stderr()
    };
}
thread_local! {
    static OUTSTREAM_FD: i32 = outstream!().as_raw_fd();
}

pub type OutStreamLock<'a> = std::io::StderrLock<'a>;

// const ENTER_ALTERNATE_SCREEN: &str = "\x1b[?1049h";
// const LEAVE_ALTERNATE_SCREEN: &str = "\x1b[?1049l";

/// This always does the syscall, because the program could be nohupped at any moment
#[inline(always)]
pub fn isatty() -> bool {
    // termion::is_tty(&outstream![])
    OUTSTREAM_FD.with(termion::is_tty)
}

#[derive(Clone, Copy)]
struct SignalMask {
    inner: u32,
}
impl SignalMask {
    pub const ZERO: Self = Self::new(0);
    pub const ONES: Self = Self::ZERO.inverse();
    pub const fn new(num: u32) -> Self {
        Self { inner: num }
    }
    pub const fn new_shift(shift_by: u32) -> Self {
        Self::new(1 << shift_by)
    }
    pub const fn get(&self) -> u32 {
        self.inner
    }
    pub const fn and(self, other: Self) -> Self {
        Self::new(self.get() & other.get())
    }
    pub const fn or(self, other: Self) -> Self {
        Self::new(self.get() | other.get())
    }
    pub const fn xor(self, other: Self) -> Self {
        Self::new(self.get() ^ other.get())
    }
    pub const fn inverse(self) -> Self {
        Self::new(!self.get())
    }
    pub const fn eq(self, other: Self) -> bool {
        self.get() == other.get()
    }
    pub const fn ne(self, other: Self) -> bool {
        !self.eq(other)
    }
}
impl Debug for SignalMask {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:b}", self.get())
    }
}

#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum SignalBits {
    UserExit = 0,
    SigInt,
    SigTerm,
    SigHup,
    SigWinch,
}
impl SignalBits {
    pub const N_MEMBERS: usize = 5;

    pub const FATAL_MASK: u32 = Self::SigInt.bitmask()
        | Self::SigTerm.bitmask()
        | Self::SigHup.bitmask()
        | Self::UserExit.bitmask();

    const SIGNAL_HANDLER_INITIALIZER_ARRAY_START_IDX: usize = 1;
    const MAX_MEMBER: u32 = Self::N_MEMBERS as u32 - 1;

    const BIT_ARRAY: [SignalMask; Self::N_MEMBERS] = {
        let mut arr: [SignalMask; Self::N_MEMBERS] = [SignalMask::ONES; Self::N_MEMBERS];

        arr[Self::UserExit as usize] = SignalMask::new_shift(Self::UserExit as u32);
        arr[Self::SigInt as usize] = SignalMask::new_shift(Self::SigInt as u32);
        arr[Self::SigTerm as usize] = SignalMask::new_shift(Self::SigTerm as u32);
        arr[Self::SigHup as usize] = SignalMask::new_shift(Self::SigHup as u32);
        arr[Self::SigWinch as usize] = SignalMask::new_shift(Self::SigWinch as u32);

        arr
    };

    const SIG_ARRAY: [c_int; Self::N_MEMBERS] = {
        let mut arr: [c_int; Self::N_MEMBERS] = [0x0; Self::N_MEMBERS];

        // UserExit is not a signal, so it should be an error to define a signal handler for it
        arr[Self::UserExit as usize] = signal_hook::consts::FORBIDDEN[0];
        arr[Self::SigInt as usize] = signal_hook::consts::SIGINT;
        arr[Self::SigTerm as usize] = signal_hook::consts::SIGTERM;
        arr[Self::SigHup as usize] = signal_hook::consts::SIGHUP;
        arr[Self::SigWinch as usize] = signal_hook::consts::SIGWINCH;

        arr
    };

    const VALID_BIT_MASK: SignalMask = {
        let mut i = 0;
        let mut acc = SignalMask::ZERO;

        while i != Self::N_MEMBERS {
            acc = acc.or(Self::BIT_ARRAY[i]);
            i += 1;
        }

        acc
    };

    #[inline(always)]
    pub const fn signal(self) -> c_int {
        Self::SIG_ARRAY[self as usize]
    }

    #[inline(always)]
    pub const fn u32(self) -> u32 {
        self as u32
    }

    #[inline(always)]
    pub const unsafe fn from_u32_unchecked(number: u32) -> Self {
        unsafe { core::mem::transmute(number) }
    }

    #[inline]
    pub const fn try_from_u32(number: u32) -> Option<Self> {
        if number > Self::MAX_MEMBER {
            return None;
        }
        // SAFETY: We bounds-checked it and made the enum repr u32
        Some(unsafe { Self::from_u32_unchecked(number) })
    }

    #[inline(always)]
    pub const fn bitmask(self) -> SignalMask {
        Self::BIT_ARRAY[self as usize]
    }

    #[inline]
    pub const fn try_from_bitmask(mask: u32) -> Option<Self> {
        if mask.count_ones() != 1 {
            return None;
        }
        Self::try_from_lowest_bit(mask)
    }

    #[inline]
    pub const fn try_from_lowest_bit(mask: u32) -> Option<Self> {
        if mask & Self::VALID_BIT_MASK != mask {
            return None;
        }

        Self::try_from_u32(mask.trailing_zeros())
    }

    pub const fn next(mask: &mut u32) -> Option<Self> {
        let Some(next_number) = Self::try_from_lowest_bit(*mask) else {
            return None;
        };

        let my_mask = next_number.bitmask();
        *mask &= !my_mask;

        Some(next_number)
    }

    /// This function is unsafe to call with anything other than [`SignalBits::UserExit`]
    /// due to delicate ordering constraints and handler thread parking
    pub unsafe fn signal_mask_store(self) {
        let loaded = SIGNAL_MASK.load(Ordering::Acquire);
        SIGNAL_MASK.store(loaded | self.bitmask(), Ordering::Release);
    }

    pub fn signal_load() -> Option<Self> {}
}

static SIGNAL_MASK: AtomicU32 = AtomicU32::new(0);
/// This is a static ptr because signal interrupts can happen on any thread
static SIGNAL_THREAD_HANDLE: AtomicPtr<JoinHandle<i32>> = AtomicPtr::new(core::ptr::null_mut());

static TERM_SIZE: AtomicU32 = AtomicU32::new(0);

pub fn update_window_size() -> io::Result<TermRect> {
    let (cols, rows) = OUTSTREAM_FD.with(termion::terminal_size_fd)?;
    let size = TermRect::new_from_raw(rows, cols);

    TERM_SIZE.store(size.pack(), Ordering::Release);
    Ok(size)
}

pub fn get_window_size() -> TermRect {
    let packed = TERM_SIZE.load(Ordering::Acquire);
    TermRect::new_from_packed(packed)
}

fn signal_isr(signal_bit: usize) {
    let handle_ptr = SIGNAL_THREAD_HANDLE.load(Ordering::Acquire);
    if handle_ptr.is_null() {
        unreachable!(
            "This condition should only ever happen if somehow, against all odds, we get a signal in the middle of std::process::exit"
        );
    }

    // SAFETY: This is only set once at startup
    let handle_thread = unsafe { &*handle_ptr }.thread();

    flag_signal(signal_bit);

    // SAFETY: inner futex_wake is guarded by an atomic that is set to Notified
    // when this function is called. Successive calls will fall through that check.
    handle_thread.unpark();
}

/// This should only be run once at startup, with no other threads running.
#[inline(always)]
pub unsafe fn signal_runtime_init() -> io::Result<()> {
    let sigthread_ptr = SIGNAL_THREAD_HANDLE.load(Ordering::Acquire);
    // This TTC/TTU is safe because we are currently the only thread running
    assert!(sigthread_ptr.is_null());

    for (bit, signal) in [
        (SIGINT_BIT, signal_hook::consts::SIGINT),
        (SIGTERM_BIT,),
        (SIGHUP_BIT,),
        (SIGWINCH_BIT,),
    ]
    .into_iter()
    {
        unsafe {
            signal_hook::low_level::register(signal, move || signal_isr(bit))?;
        }
    }

    let handle = std::thread::Builder::new()
        .name("sigloop".into())
        .spawn(sigloop)?;

    let leaked = Box::into_raw(Box::new(handle));
    SIGNAL_THREAD_HANDLE.store(leaked, Ordering::Release);

    Ok(())
}

fn sigloop() -> i32 {
    let rval;

    let screen_guard = outstream![]
        .into_alternate_screen()
        .expect("Failed to switch to the alternate terminal buffer!");

    loop {
        std::thread::park();
        let mask = SIGNAL_MASK.swap(0, Ordering::AcqRel);

        // This is mostly here for testing thread parking
        println!("mask: {:b}", mask);

        if mask == 0 {
            continue;
        }

        if mask & SIGWINCH_BIT != 0 {
            update_window_size().expect("Failed to get current terminal size!");
        }

        // TODO: These are arbitrary numbers, decide on better ones
        if mask & FATAL_MASK != 0 {
            if mask & USER_EXIT_REQ != 0 {
                rval = 0;
            } else if mask & SIGINT_BIT != 0 {
                rval = 127;
            } else if mask & SIGTERM_BIT != 0 {
                rval = 24;
            } else if mask & SIGHUP_BIT != 0 {
                unimplemented!("SIGHUP is not supported by this application!");
                // rval = -1;
            } else {
                unreachable!();
            }
            break;
        }
    }

    drop(screen_guard);

    rval
}

pub fn block_join_sigloop() -> i32 {
    let sigthread_ptr = SIGNAL_THREAD_HANDLE.load(Ordering::Acquire);
    assert_ne!(sigthread_ptr, core::ptr::null_mut());
    unsafe { Box::from_raw(sigthread_ptr) }
        .join()
        .expect("Failed to join signal thread")
}

// #[inline(always)]
// pub fn get_window_size() -> Result<Winsize, Errno> {
//     rustix::termios::tcgetwinsize(STDOUT_FD)
// }

pub fn non_recursively_copy_contents_of_directory_with_fancy_tui_progressbar(
    source_folder: impl Into<PathBuf>,
    dst_folder: impl AsRef<Path>,
) -> io::Result<()> {
    let source_folder = source_folder.into();

    let mut non_dir_list = Vec::new();
    let mut dir_list = vec![source_folder.clone()];

    let mut dir_list_cursor = 0;

    while dir_list_cursor != dir_list.len() {
        let listed = dir_list[dir_list_cursor].read_dir()?;
        for entry in listed {
            let entry = entry?;
            let entry_path = entry.path();

            if entry.file_type()?.is_dir() {
                dir_list.push(entry_path);
            } else {
                non_dir_list.push(entry_path);
            }
        }

        dir_list_cursor += 1;
    }

    todo!("Finish");
    Ok(())
}

/// tries real hard to do what it says on the tin
#[cfg(test)]
fn recursively_copy_contents_of_directory(
    src: impl AsRef<Path>,
    dst_folder: impl AsRef<Path>,
) -> io::Result<()> {
    let src = src.as_ref();
    let dst_folder = dst_folder.as_ref();

    for entry in src.read_dir()? {
        let entry = entry?;
        let ty = entry.file_type()?;
        let epath = entry.path();
        let destination = dst_folder.join(entry.file_name());

        if ty.is_dir() {
            std::fs::create_dir_all(/* folder */ &destination)?;
            recursively_copy_contents_of_directory(&epath, /* folder */ &destination)?;
        } else {
            std::fs::copy(&epath, /* file */ &destination)?;
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_recursively_copy_contents_of_directory() {
        assert!(
            recursively_copy_contents_of_directory(
                "/boot/some_random_folder_name_or_something_unreasonably_named",
                "target"
            )
            .is_err()
        );
    }
}

#![allow(static_mut_refs)]

use {
    crate::tui::TermRect,
    ::core::{
        cell::Cell,
        ffi::{c_int, c_void},
        fmt::Debug,
        marker::PhantomData,
        mem::MaybeUninit,
        num::{NonZeroI32, NonZeroU32},
        sync::atomic::{AtomicBool, AtomicPtr, AtomicU32, Ordering},
    },
    ::signal_hook::SigId,
    ::std::{
        io::{Result as IoResult, Write},
        os::unix::prelude::AsRawFd,
        path::{Path, PathBuf},
        sync::Mutex,
        thread::{JoinHandle, Thread},
    },
    ::termion::screen::IntoAlternateScreen,
};

#[macro_export]
macro_rules! outstream {
    () => {
        ::std::io::stdout()
    };
    ($fmt:literal $( , $arg:expr )*) => {
        ::std::writeln!(outstream![], $fmt $( , $arg )*)
    };
}

pub const OUTSTREAM_FD: i32 = 1;

#[inline(always)]
pub fn isatty() -> bool {
    // termion::is_tty(&outstream![])
    termion::is_tty(&OUTSTREAM_FD)
}

macro_rules! signal_bits {
    ($( $signal:ident ),+$(,)?) => {
        #[repr(u32)]
        #[allow(non_camel_case_types)]
        #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
        pub enum SignalKind {
            $( $signal, )+
        }

        impl SignalKind {
            pub const N_MEMBERS: usize = *&[$( Self::$signal ),+].len();
            pub const BIT_ARRAY: [u32; Self::N_MEMBERS] = [
                $( 1 << (Self::$signal as u32) ),+
            ];
            pub const ENUM_ARRAY: [Self; Self::N_MEMBERS] = [
                $(Self::$signal),+
            ];
            pub const SIGNAL_ARRAY: [c_int; Self::N_MEMBERS] = [
                $( ::signal_hook::consts::$signal ),+
            ];
        }
    };
}
signal_bits! {
    SIGINT,
    SIGTERM,
    SIGHUP,
    SIGWINCH,
}
impl SignalKind {
    pub const FATAL_MASK: u32 =
        Self::SIGINT.bitmask() | Self::SIGTERM.bitmask() | Self::SIGHUP.bitmask();

    pub const BIT_VALID_RANGE_MASK: u32 = {
        let mut i = 0;
        let mut acc = 0;

        while i != Self::N_MEMBERS {
            acc = acc | Self::BIT_ARRAY[i];
            i += 1;
        }

        acc
    };

    #[inline(always)]
    pub const fn signal(self) -> c_int {
        Self::SIGNAL_ARRAY[self as usize]
    }
    #[inline(always)]
    pub const fn bitmask(self) -> u32 {
        Self::BIT_ARRAY[self as usize]
    }
    #[inline]
    pub const fn try_from_lowest_bit(mask: u32) -> Option<Self> {
        let num = mask.trailing_zeros();
        if num > Self::N_MEMBERS as u32 {
            return None;
        }

        Some(unsafe { Self::from_repr_unchecked(num) })
    }

    #[inline(always)]
    pub const unsafe fn from_repr_unchecked(number: u32) -> Self {
        unsafe { core::mem::transmute(number) }
    }

    pub fn run_handler(self) -> i32 {
        match self {
            Self::SIGWINCH => {
                crate::tui::update_window_size().expect("Failed to update window size");
                0
            }
            Self::SIGHUP => 32,
            Self::SIGINT => 127,
            Self::SIGTERM => 143,
        }
    }
}

pub struct TermHandle<'l> {
    inner: termion::screen::AlternateScreen<std::io::StdoutLock<'l>>,
    phant: PhantomData<*const ()>,
}
impl<'l> TermHandle<'l> {
    pub fn new() -> Self {
        let lock = outstream!()
            .lock()
            .into_alternate_screen()
            .expect("Failed to switch to the alternate terminal buffer!");

        Self {
            inner: lock,
            phant: PhantomData,
        }
    }

    pub fn write_infallible(&mut self, args: core::fmt::Arguments<'_>) {
        self.inner
            .write_fmt(args)
            .expect("Failed to write to outstream!");
    }

    pub fn write_str_infallible(&mut self, s: &str) {
        self.inner
            .write_all(s.as_bytes())
            .expect("Failed to write to outstream!");
    }
}
impl<'l> Write for TermHandle<'l> {
    fn write(&mut self, buf: &[u8]) -> IoResult<usize> {
        self.inner.write(buf)
    }
    fn write_all(&mut self, buf: &[u8]) -> IoResult<()> {
        self.inner.write_all(buf)
    }
    fn write_fmt(&mut self, args: std::fmt::Arguments<'_>) -> IoResult<()> {
        self.inner.write_fmt(args)
    }
    fn by_ref(&mut self) -> &mut Self
    where
        Self: Sized,
    {
        self
    }
    fn write_vectored(&mut self, bufs: &[std::io::IoSlice<'_>]) -> IoResult<usize> {
        self.inner.write_vectored(bufs)
    }
    fn flush(&mut self) -> IoResult<()> {
        self.inner.flush()
    }
}

/// This is a static because signal interrupts can happen on any thread
static SIG_THREAD_HANDLE: SigThread = SigThread {
    running_thread: AtomicPtr::new(core::ptr::null_mut()),
    signal_mask: AtomicU32::new(0),
    actions: Mutex::new([MaybeUninit::uninit(); SignalKind::N_MEMBERS]),
};

pub struct SigThread {
    running_thread: AtomicPtr<Thread>,
    signal_mask: AtomicU32,
    actions: Mutex<[MaybeUninit<SigId>; SignalKind::N_MEMBERS]>,
}
impl SigThread {
    pub const THREAD_NAME: &'static str = "sigloop";
    pub const PREFERRED_LOAD_ORDERING: Ordering = Ordering::Acquire;
    pub const PREFERRED_STORE_ORDERING: Ordering = Ordering::Release;
    pub const PREFERRED_SWAP_ORDERING: Ordering = Ordering::AcqRel;

    pub const USER_EXIT_REQ: u32 = {
        let to_ret = 0x80_00_00_00;

        let mut i = 0;
        while i < SignalKind::N_MEMBERS {
            if to_ret & SignalKind::BIT_ARRAY[i] != 0 {
                panic!("Invalid user exit request mask, byte already reserved");
            }
            i += 1;
        }

        to_ret
    };

    /// Runs to completion
    #[inline(always)]
    pub fn sigloop(term: &mut TermHandle<'_>) -> ! {
        let ret = SIG_THREAD_HANDLE.sigloop_inner(term);

        std::process::exit(ret)
    }

    #[inline(always)]
    fn sigloop_inner(&self, term: &mut TermHandle<'_>) -> i32 {
        self.running_thread.store(
            Box::into_raw(Box::new(std::thread::current())),
            Self::PREFERRED_STORE_ORDERING,
        );

        {
            let mut actions = self.actions.lock().unwrap();

            for signal in SignalKind::ENUM_ARRAY {
                actions[signal as usize].write(unsafe {
                    signal_hook::low_level::register(signal.signal(), move || {
                        SIG_THREAD_HANDLE.send_signal(signal)
                    })
                    .expect("Failed to register signal")
                });
            }
        }

        term.write_str_infallible("Signal loop started");

        loop {
            // core::hint::spin_loop();
            // std::thread::park();
            let Some(mask) = self.take_signals() else {
                std::thread::yield_now();
                continue;
            };

            term.write_infallible(format_args!("mask: {:b}", mask.get()));

            if mask.get() & Self::USER_EXIT_REQ != 0 {
                return 0;
            }

            let mut idx = 0;
            for signal_mask in SignalKind::BIT_ARRAY {
                if signal_mask & mask.get() == 0 {
                    continue;
                }
                // SAFETY: The enum reprs are the same as indices
                let rval = SignalKind::ENUM_ARRAY[idx].run_handler();
                if rval == 0 {
                    return rval;
                }
                idx += 1;
            }
        }
    }

    pub fn send_signal(&self, signal: SignalKind) {
        let to_store = self
            .signal_mask
            .fetch_or(signal.bitmask(), Self::PREFERRED_LOAD_ORDERING);
        self.signal_mask
            .store(to_store, Self::PREFERRED_STORE_ORDERING);

        // If this is a null pointer I would want the process to exit anyways. SIGSEV is actually more reliable than a rust panic for this purpose
        unsafe { &*self.running_thread.load(Self::PREFERRED_LOAD_ORDERING) }.unpark();
    }

    #[inline]
    fn take_signals(&self) -> Option<NonZeroU32> {
        let mask = self.signal_mask.swap(0, Self::PREFERRED_SWAP_ORDERING);
        NonZeroU32::new(mask)
    }
}

pub fn non_recursively_copy_contents_of_directory_with_fancy_tui_progressbar(
    source_folder: impl Into<PathBuf>,
    dst_folder: impl AsRef<Path>,
) -> IoResult<()> {
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
) -> IoResult<()> {
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

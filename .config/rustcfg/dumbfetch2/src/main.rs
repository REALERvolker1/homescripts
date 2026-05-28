#![no_std]
#![no_main]

pub mod cachefile;
pub mod cli;
pub mod entry;
pub mod info;
pub mod io;
pub mod ram;
pub mod syscall;

use ::core::ffi::{c_char, c_int};

use ::arrayvec::ArrayVec;

use crate::io::LibcWrite;

#[cfg(not(test))]
#[panic_handler]
fn panic(_info: &::core::panic::PanicInfo) -> ! {
    unsafe { libc::exit(1) }
}

const fn max(a: usize, b: usize) -> usize {
    if a > b { a } else { b }
}

#[unsafe(no_mangle)]
pub extern "C" fn main(argc: c_int, argv: *mut *mut c_char) -> c_int {
    // SAFETY: This is the `main` function
    if let Some(args) = unsafe { cli::ArgIter::new(argc, argv) } {
        args.for_each(|a| {
            _ = io::Stdout.write(a.to_bytes());
        })
    }

    unsafe { libc::sleep(1) };

    let mut a = ArrayVec::<_, 1024>::new();

    let mut random_ass_memory: ram::RandomAssMemory = Default::default();

    // SAFETY: We conservatively assume it is uninitl
    info::kernel::try_append_kernel(&mut a, unsafe { &mut random_ass_memory.utsname });

    a.push(b'\t');

    info::uptime::append_uptime(
        &mut a,
        unsafe { &mut random_ass_memory.sysinfo.info },
        unsafe { &mut random_ass_memory.sysinfo.buf },
    );
    _ = io::Stdout.write(a.as_slice());

    panic!();

    // unsafe {
    //     puts(PRINT_MSG);
    //     exit(69);
    // }
}

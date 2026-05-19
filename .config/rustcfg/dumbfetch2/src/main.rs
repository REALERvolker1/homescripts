#![no_std]
#![no_main]

pub mod cachefile;
pub mod entry;
pub mod info;
pub mod io;

use ::core::ffi::{CStr, c_int};

#[cfg(not(test))]
#[panic_handler]
fn panic(_info: &::core::panic::PanicInfo) -> ! {
    unsafe { libc::exit(1) }
}

#[unsafe(no_mangle)]
pub extern "C" fn main() -> c_int {
    const PRINT_MSG: &CStr = c"This is a message!";

    unsafe { libc::sleep(5) };
    panic!("Exiting");

    // unsafe {
    //     puts(PRINT_MSG);
    //     exit(69);
    // }
}

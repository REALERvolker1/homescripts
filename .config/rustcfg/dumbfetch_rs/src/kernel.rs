use rustix::path::Arg;

use crate::{entry::Entry, undef};

pub fn get_kernel() -> Entry {
    let uname = rustix::system::uname();
    let release = uname.release();

    let version = undef!(@err release.as_str(), "Kernel");

    // Linux version 6.8.1-273-tkg-bore-llvm (linux68-tkg-bore-llvm@archlinux) (clang version 17.0.6, LLD 17.0.6) #1 SMP PREEMPT_DYNAMIC TKG Wed, 20 Mar 2024 21:00:27 +0000
    // let version_str = undef!(@opt version.split(' ').nth(2), "Kernel");

    Entry::new("Kernel", version.to_owned())
}

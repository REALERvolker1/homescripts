use crate::{entry::Entry, undef};

const ALLOWED_FS: [&str; 4] = ["ext4", "xfs", "btrfs", "ntfs"];

pub fn get_disk() -> Entry {
    // let stat = nix::sys::sysinfo::sysinfo();
    let mount_file = undef!(@err std::fs::read_to_string("/proc/mounts"), "Disk");
    /*
    /dev/nvme0n1p1 / ext4 rw,relatime 0 0
    */

    let mounts = mount_file
        .lines()
        .filter_map(|line| {
            let mut line = line.split(' ').skip(1);
            // let device = line.next()?;
            let mountpoint = line.next()?;
            let fs = line.next()?;

            Some((mountpoint, fs))
        })
        .filter(|(_, fs)| ALLOWED_FS.contains(fs))
        .filter_map(|(mountpoint, _)| {
            // let stat = nix::sys::statfs::statfs(mountpoint).ok()?;
            // unsafe {
            //     let mut stat = std::mem::MaybeUninit::<type_of_statfs>::uninit();
            //     let res =
            //         path.with_nix_path(|path| LIBC_STATFS(path.as_ptr(), stat.as_mut_ptr()))?;
            //     Errno::result(res).map(|_| Statfs(stat.assume_init()))
            // }

            // friendship ended with nix, now rustix is my friend

            let stat = rustix::fs::statfs(mountpoint).ok()?;

            // accuracy is kinda garbage
            let total = stat.f_blocks;
            let free = stat.f_bavail;

            let percent = (free * 100) / total;

            Some(format!("[{mountpoint}] {percent}%"))
        })
        .collect::<Vec<_>>();

    if mounts.is_empty() {
        return undef!("Disk").unwrap();
    }

    Entry::new("Disk", mounts.join(", "))
}

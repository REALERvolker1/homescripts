use {
    crate::io::read_into_buffer,
    ::arrayvec::ArrayVec,
    ::core::{
        ffi::{CStr, c_int},
        mem::MaybeUninit,
        num::NonZero,
        ops::ControlFlow,
    },
};

#[inline]
#[must_use]
pub const fn color_for_allowed_filesystem<const USE_BRIGHT: bool>(fs: &[u8]) -> Option<u8> {
    let base = if USE_BRIGHT { 90 } else { 30 };
    let hue = match fs {
        b"ext4" => 4,
        b"xfs" => 3,
        b"btrfs" => 2,
        b"ntfs" => 6,
        _ => return None,
    };

    Some(base + hue)
}

pub fn parse_proc_mounts(
    file_content: &mut [u8],
) -> impl Iterator<Item: Iterator<Item = &mut [u8]>> {
    #[inline]
    const fn not_empty(s: &&mut [u8]) -> bool {
        !s.is_empty()
    }
    #[inline]
    const fn is_newline(c: &u8) -> bool {
        *c == b'\n'
    }
    #[inline]
    const fn is_ascii_whitespace(c: &u8) -> bool {
        c.is_ascii_whitespace()
    }
    #[inline]
    fn line_space_iter(line: &mut [u8]) -> impl Iterator<Item = &mut [u8]> {
        line.split_mut(is_ascii_whitespace).filter(not_empty)
    }

    file_content
        .split_mut(is_newline)
        .filter(not_empty)
        .map(line_space_iter)
}

fn get_available_allowed_filesystems<const USE_BRIGHT: bool>(
    read_buf: &mut [MaybeUninit<u8>],
) -> Option<usize> {
    let disks = read_into_buffer(c"/proc/mounts", read_buf).ok()?;

    let content = parse_proc_mounts(disks).filter_map(|mut c| {
        let _fs_spec = c.next()?;
        let mountpoint = c.next()?;
        let fstype = c.next()?;

        fstype.iter_mut().for_each(|c| *c = c.to_ascii_lowercase());
        let fstype_color = color_for_allowed_filesystem::<USE_BRIGHT>(fstype)?;

        Some((mountpoint, fstype_color))
    });

    todo!();
}

// pub fn try_append_disks<const N: usize>(
//     buf: &mut ArrayVec<u8, N>,
//     read_buf: &mut [MaybeUninit<u8>],
// ) -> Option<NonZero<usize>> {
//     let disks = read_into_buffer(c"/proc/mounts", read_buf).ok()?;

//     // parse_proc_mounts(disks).for_each(f)
// }

use {
    crate::{io::ArrayVecExt, syscall::sysinfo},
    ::arrayvec::ArrayVec,
    ::core::{mem::MaybeUninit, num::NonZero},
};

/// div_rem, but with NonZero to enforce nonzero invariants
#[inline]
const fn div_rem(num: u64, denom: NonZero<u64>) -> (u64, u64) {
    (num / denom.get(), num % denom.get())
}

#[derive(Default)]
#[repr(C)]
struct Uptime {
    pub days: u8,
    pub hours: u8,
    pub minutes: u8,
    pub seconds: u8,
}
impl Uptime {
    #[must_use]
    pub const fn new(total_seconds: u64) -> Self {
        const SIXTY: NonZero<u64> = NonZero::new(60).unwrap();
        const TWENTYFOUR: NonZero<u64> = NonZero::new(24).unwrap();

        let (total_minutes, seconds) = div_rem(total_seconds, SIXTY);
        let (total_hours, minutes) = div_rem(total_minutes, SIXTY);
        let (days, hours) = div_rem(total_hours, TWENTYFOUR);

        Self {
            days: days as _,
            hours: hours as _,
            minutes: minutes as _,
            seconds: seconds as _,
        }
    }
    #[inline(always)]
    pub const fn dhms_array(self) -> [u8; 4] {
        // SAFETY: This type is `repr(C)` and `Pod`
        unsafe { core::mem::transmute(self) }
    }

    const FIELDS_STRINGS: [&str; 4] = ["d", "h", "m", "s"];

    #[must_use]
    #[inline(always)]
    pub fn from_sysinfo(sysinfo: &libc::sysinfo) -> Self {
        Self::new(sysinfo.uptime.unsigned_abs())
    }
}

fn append_time_segment_to_arrayvec<const N: usize>(
    buf: &mut ArrayVec<u8, N>,
    ibuf: &mut itoa::Buffer,
    string: &str,
    time: u8,
) -> Option<NonZero<usize>> {
    let timefmt = ibuf.format(time);
    buf.try_extend_from_slice(timefmt.as_bytes()).ok()?;

    let mut res = timefmt.len();

    let mut slen = string.len();
    if time == 1 {
        slen -= 1;
    };

    // if buf.try_push(b' ').is_err() {
    //     return NonZero::new(res);
    // } else {
    //     res += 1;
    // }

    res += buf.extend_some_from_slice(&(string.as_bytes())[..slen]);

    NonZero::new(res)
}

pub fn append_uptime<const N: usize>(
    buf: &mut ArrayVec<u8, N>,
    ubuf: &mut MaybeUninit<libc::sysinfo>,
    ibuf: &mut itoa::Buffer,
) -> Option<NonZero<usize>> {
    let info = sysinfo(ubuf).ok()?;

    let time = Uptime::from_sysinfo(info);

    let mut acc: usize = 0;

    time.dhms_array()
        .iter()
        .copied()
        .zip(Uptime::FIELDS_STRINGS.iter().copied())
        .try_fold(false, |has_found_nonzero, (time, string)| {
            if !has_found_nonzero {
                if time == 0 {
                    return Some(false);
                }
            } else {
                // first iteration should not prepend commas
                const SEP: &[u8] = b" ";
                buf.try_extend_from_slice(SEP).ok()?;
                acc = acc.saturating_add(SEP.len());
            }

            let n = append_time_segment_to_arrayvec(buf, ibuf, string, time)?;

            acc = acc.saturating_add(n.get());

            Some(true)
        });

    NonZero::new(acc)
}

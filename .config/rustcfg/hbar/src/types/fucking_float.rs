use super::Percent;
use std::fmt;

macro_rules! imp {
    ($($f:ty),+) => {
        $(impl From<$f> for FuckingFloat {
            fn from(f: $f) -> Self {
                Self {
                    whole: f.trunc() as usize,
                    perc: Percent::from_decimal(f.into()),
                }
            }
        })+
    };
}

/// A float I can fucking [`Eq`]. Only supports decimals up to the hundreds place.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
pub struct FuckingFloat {
    pub whole: usize,
    pub perc: Percent,
}
impl FuckingFloat {
    pub const MIN: Self = Self {
        whole: usize::MIN,
        perc: Percent::MIN,
    };
    pub const MAX: Self = Self {
        whole: usize::MAX,
        perc: Percent::MAX,
    };
}
imp!(f32, f64);
impl fmt::Display for FuckingFloat {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let my_perc: u8 = self.perc.into();
        write!(f, "{}.{}", self.whole, my_perc)
    }
}

use crate::*;

macro_rules! tryfrm {
    ($($type:ty),+) => {
        $(
            impl TryFrom<$type> for Percent {
                type Error = BruhMoment;
                fn try_from(value: $type) -> Result<Self, Self::Error> {
                    Self::new(value.try_into()?)
                }
            }
        )+
    };
}

#[derive(
    Debug,
    Default,
    Clone,
    Copy,
    PartialEq,
    Eq,
    PartialOrd,
    Ord,
    Hash,
    zbus::zvariant::Type,
    derive_more::Display,
    derive_more::AsRef,
    Serialize,
    Deserialize,
)]
#[as_ref(forward)]
pub struct Percent(u8);
impl Percent {
    pub fn new(u: u8) -> Bruh<Self> {
        if u > 100 {
            Err(BruhMoment::Conversion(format!(
                "percent value '{u}' out of range"
            )))
        } else {
            Ok(Self(u))
        }
    }
    pub fn from_decimal(float_number: f64) -> Self {
        // modulus 1.0 to make sure it won't overflow when I multiply
        let num = (float_number % 1.0) * 100.0;

        // it was already a percent to begin with, just convert it into the right type
        Self(num.round() as u8)
    }
}
tryfrm!(u8, u16, u32, u64, usize, i8, i16, i32, i64, isize);

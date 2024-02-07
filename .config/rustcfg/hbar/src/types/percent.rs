use crate::*;

/// A checked Percentage, from 0 to 100
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
    zvariant::Type,
    derive_more::Display,
    derive_more::AsRef,
    derive_more::Into,
    Serialize,
    Deserialize,
)]
#[as_ref(forward)]
#[display(fmt = "{}%", _0)]
pub struct Percent(u8);
impl Percent {
    pub const MAX: Self = Self(100);
    pub const MIN: Self = Self(0);
    /// Create a new Percentage. This function will return an error if the value is greater than 100.
    pub fn new(u: u8) -> ModResult<Self> {
        if u > 100 {
            Err(ModError::InvalidInt(u as isize))
        } else {
            Ok(Self(u))
        }
    }
    /// Create a new [`Percent`] from a floating-point number.
    pub fn from_decimal(float_number: f64) -> Self {
        // modulus 1.0 to make sure it won't overflow when I multiply
        let num = (float_number % 1.0) * 100.0;

        // it was already a percent to begin with, just convert it into the right type
        Self(num.round() as u8)
    }
    pub fn of_numbers(numerator: u64, denominator: u64) -> Self {
        Self(((numerator * 100) / denominator) as u8)
    }
}
macro_rules! tryfrm {
    ($($type:ty),+) => {
        $(
            impl TryFrom<$type> for Percent {
                type Error = ModError;
                fn try_from(value: $type) -> Result<Self, Self::Error> {
                    Self::new(value.try_into()?)
                }
            }
        )+
    };
}
tryfrm!(u8, u16, u32, u64, usize, i8, i16, i32, i64, isize);
impl TryFrom<f64> for Percent {
    type Error = ModError;
    fn try_from(value: f64) -> Result<Self, Self::Error> {
        Self::new(value.round() as u8)
    }
}
impl FromStr for Percent {
    type Err = ModError;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::new(s.parse()?)
    }
}
impl TryFrom<zvariant::OwnedValue> for Percent {
    type Error = zbus::Error;
    fn try_from(value: zvariant::OwnedValue) -> Result<Self, Self::Error> {
        let operation_result = if let Some(v) = value.downcast_ref::<f64>() {
            Self::try_from(v.floor())
        } else if let Some(v) = value.downcast_ref::<u8>() {
            Self::try_from(*v)
        } else {
            Err(ModError::Fmt(format!(
                "Failed to parse percentage from value! {:?}",
                value
            )))
        };

        // convert it into an error compatible with zbus-xmlgen stuff
        match operation_result {
            Ok(v) => Ok(v),
            Err(ModError::FromInt(_)) | Err(ModError::InvalidInt(_)) => {
                Err(zbus::Error::Variant(zvariant::Error::OutOfBounds))
            }
            Err(ModError::Fmt(e)) => Err(zbus::Error::Failure(e)),
            _ => unreachable!(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn in_range() {
        assert_eq!(Percent::new(69).unwrap(), Percent(69));
    }

    #[test]
    fn out_of_range() {
        assert!(Percent::new(101).is_err());
    }

    #[test]
    fn from_decimal() {
        assert_eq!(Percent::from_decimal(0.69), Percent(69));
    }
}

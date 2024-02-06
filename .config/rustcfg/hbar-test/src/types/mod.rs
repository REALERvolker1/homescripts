pub mod error;
pub mod icon;
pub mod percent;

use crate::*;
pub use error::*;
pub use icon::*;
pub use percent::*;

/// A boolean, but allows for the Auto value instead of just true or false.
///
/// useful for configuration
#[derive(
    Debug, Default, Clone, Copy, PartialEq, Eq, strum_macros::Display, Serialize, Deserialize,
)]
pub enum AutoBool {
    True,
    False,
    #[default]
    Auto,
}

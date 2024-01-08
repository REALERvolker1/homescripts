use std::{error, fmt, io};

/// The main error type for this program
#[derive(Debug)]
pub enum TuError {
    Io(io::Error),
    Any(Box<dyn error::Error>),
    Conversion(Box<dyn fmt::Debug>),
    Custom(String),
}

impl TuError {
    pub fn custom(error_message: &str) -> Self {
        Self::Custom(String::from(error_message))
    }
}
impl From<io::Error> for TuError {
    fn from(e: io::Error) -> Self {
        Self::Io(e)
    }
}

impl error::Error for TuError {}

impl fmt::Display for TuError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            TuError::Io(e) => e.fmt(f),
            TuError::Any(e) => e.fmt(f),
            TuError::Conversion(e) => write!(f, "Error converting '{:?}'", e),
            TuError::Custom(e) => write!(f, "Error: {}", e),
        }
    }
}

// /// Basically a nicer way to return this program's errors
// #[derive(Debug)]
// pub enum TuResult<T> {
//     Ok(T),
//     Err(TuError),
// }

// impl<T> TuResult<T> {
//     pub fn ok(&self) -> Option<T> {
//         match self {
//             TuResult::Ok(e) => Some(*e),
//             TuResult::Err(e) => None,
//         }
//     }
//     pub fn from_option(disp: Option<T>, error_message: &str) -> TuResult<T> {
//         match disp {
//             Some(e) => TuResult::Ok(e),
//             None => TuResult::Err(TuError::Custom(String::from(error_message))),
//         }
//     }
//     pub fn from_result(result: Result<T, TuError>) -> TuResult<T> {
//         match result {
//             Ok(e) => TuResult::Ok(e),
//             Err(e) => TuResult::Err(e),
//         }
//     }
// }

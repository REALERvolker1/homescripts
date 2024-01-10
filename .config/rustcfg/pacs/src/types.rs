#[derive(Debug, strum_macros::Display)]
pub enum PacsError {
    Other(String),
}
impl std::error::Error for PacsError {}

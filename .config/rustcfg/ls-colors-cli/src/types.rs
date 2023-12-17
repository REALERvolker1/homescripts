#[derive(Debug, Clone)]
pub struct File {
    pub recursive: bool,
    pub error: bool,
    pub ansi_only: bool,
    pub file: String,
}
impl Default for File {
    fn default() -> Self {
        Self {
            recursive: true,
            error: false,
            ansi_only: false,
            file: "".to_owned(),
        }
    }
}

#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Serialize,
    Deserialize,
    clap::ValueEnum,
    strum_macros::Display,
    strum_macros::AsRefStr,
    strum_macros::VariantNames,
)]
#[strum(serialize_all = "kebab-case")]
#[serde(rename_all = "kebab-case")]
#[value(rename_all = "kebab-case")]
pub enum LogLevel {
    Warn,
    Info,
    Debug,
    Trace,
}
impl Default for LogLevel {
    fn default() -> Self {
        #[cfg(not(debug_assertions))]
        return Self::Warn;

        #[cfg(debug_assertions)]
        return Self::Debug;
    }
}
impl LogLevel {
    pub fn tracing(self) -> Lf {
        match self {
            Self::Warn => Lf::WARN,
            Self::Info => Lf::INFO,
            Self::Debug => Lf::DEBUG,
            Self::Trace => Lf::TRACE,
        }
    }
}
type Lf = tracing::level_filters::LevelFilter;

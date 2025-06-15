use {::ahash::HashMap, ::core::cell::Cell};

pub const C_LANG: StaticLanguageDefinition = StaticLanguageDefinition::new("C", "*.c", "38;5;81");
pub const CPP_LANG: StaticLanguageDefinition =
    StaticLanguageDefinition::new("C++", "*.cpp", "38;5;87");
pub const RUST_LANG: StaticLanguageDefinition =
    StaticLanguageDefinition::new("Rust", "*.rs", "38;5;172");
pub const JAVA_LANG: StaticLanguageDefinition =
    StaticLanguageDefinition::new("Java", "*.java", "38;5;130");
pub const HTML_LANG: StaticLanguageDefinition =
    StaticLanguageDefinition::new("HTML", "*.html", "38;5;208");
pub const CSS_LANG: StaticLanguageDefinition =
    StaticLanguageDefinition::new("CSS", "*.css", "38;5;27");
pub const JS_LANG: StaticLanguageDefinition =
    StaticLanguageDefinition::new("Javascript", "*.js", "38;5;193");
pub const TS_LANG: StaticLanguageDefinition =
    StaticLanguageDefinition::new("Typescript", "*.ts", "38;5;33");

thread_local! {
    static LANGUAGE_TABLE: HashMap<&'static str, StaticLanguageDefinition> = [
            (C_LANG.name, C_LANG),
            (CPP_LANG.name, CPP_LANG),
            (RUST_LANG.name, RUST_LANG),
            (JAVA_LANG.name, JAVA_LANG),
            (HTML_LANG.name, HTML_LANG),
            (CSS_LANG.name, CSS_LANG),
            (JS_LANG.name, JS_LANG),
            (TS_LANG.name, TS_LANG),
        ]
        .into_iter()
        .collect();
}

pub trait LanguageDisplay {
    fn name(&self) -> &str;
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct StaticLanguageDefinition {
    pub name: &'static str,
    pub lscolors_key: &'static str,
    pub fallback_color: &'static str,
    disp_cache: Cell<Option<&'static str>>,
}
impl StaticLanguageDefinition {
    pub const fn new(
        name: &'static str,
        lscolors_key: &'static str,
        fallback_color: &'static str,
    ) -> Self {
        Self {
            name,
            lscolors_key,
            fallback_color,
            disp_cache: Cell::new(None),
        }
    }
}
impl LanguageDisplay for StaticLanguageDefinition {
    fn name(&self) -> &str {
        if let Some(c) = self.disp_cache.get() {
            return c;
        }

        self.disp_cache.set({
            if crate::io_methods::isatty() {
                let heapstr = format!(
                    "\x1b[{}m{}\x1b[0m",
                    match crate::env::ls_colors_lookup(self.lscolors_key) {
                        Some(s) => s,
                        None => self.fallback_color,
                    },
                    self.name
                )
                .into_boxed_str();

                let str_ref = Box::leak(heapstr);

                Some(str_ref)
            } else {
                Some(self.name)
            }
        });

        self.disp_cache.get().unwrap()
    }
}

pub enum DynamicLanguageDefinition {
    Static(StaticLanguageDefinition),
    Custom(Box<str>),
}
impl DynamicLanguageDefinition {
    pub fn new(lang_key: Box<str>) -> Self {
        // SAFETY: This is in a thread local, the hashmap we are getting this from is going to live forever
        match LANGUAGE_TABLE.with(|l| l.get(&*lang_key).cloned()) {
            Some(s) => Self::Static(s),
            None => Self::Custom(lang_key),
        }
    }
}
impl LanguageDisplay for DynamicLanguageDefinition {
    fn name(&self) -> &str {
        match self {
            Self::Static(s) => s.name(),
            Self::Custom(s) => &s,
        }
    }
}

impl<T, L> LanguageDisplay for T
where
    L: LanguageDisplay,
    T: IntoIterator<Item = L>,
{
    fn name(&self) -> &str {
        // let mut my_iter = self.into_iter();
        unimplemented!();
    }
}

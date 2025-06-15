//! TODO: Add more:
//!
//! - C/C++ with cmake or meson/ninja
//! - C with nvidia cuda
//! - rust no_std
//! - Minecraft mod for 1.20.1 forge, 1.21.1 neoforge, or 1.21.4 fabric
//! - Typescript frontend

use {
    crate::langs::{DynamicLanguageDefinition, LanguageDisplay},
    ::serde_derive::{Deserialize, Serialize},
    ::std::{
        io::{self, Read, Seek},
        path::{Path, PathBuf},
    },
};

pub mod c;
pub mod rust;
pub mod web;

pub const RUNTIME_TEMPLATE_FNAME: &[u8] = b"template.toml";

pub trait Template<T: LanguageDisplay> {
    fn language(&self) -> &T;
    fn name(&self) -> &str;
    fn description(&self) -> &str;

    type CreateProjectError: std::error::Error;
    fn create_project(&self, path: &Path) -> Result<(), Self::CreateProjectError>;
}

pub struct RuntimeTemplate {
    pub language: DynamicLanguageDefinition,
    pub name: String,
    pub description: String,
    pub folder: PathBuf,
}
impl RuntimeTemplate {
    pub fn new(hpath: &Path, parent: &Path) -> Result<Self, Box<dyn std::error::Error>> {
        let mut fh = std::fs::File::open(hpath)?;
        let expected = fh.seek(::std::io::SeekFrom::Start(0))?;
        let mut buf = Vec::with_capacity(expected as usize);
        fh.read_to_end(&mut buf)?;

        #[derive(Debug, Serialize, Deserialize)]
        struct RuntimeTemplateHeader {
            pub language: String,
            pub name: String,
            pub description: String,
        }

        let desere = toml_edit::de::from_slice::<RuntimeTemplateHeader>(&buf)?;

        debug_assert!(parent.is_dir());

        Ok(RuntimeTemplate {
            language: DynamicLanguageDefinition::new(desere.language.into_boxed_str()),
            name: desere.name,
            description: desere.description,
            folder: parent.to_path_buf(),
        })
    }
}
impl Template<DynamicLanguageDefinition> for RuntimeTemplate {
    fn language(&self) -> &DynamicLanguageDefinition {
        return &self.language;
    }
    fn name(&self) -> &str {
        return &self.name;
    }
    fn description(&self) -> &str {
        return &self.description;
    }

    type CreateProjectError = std::io::Error;
    fn create_project(&self, path: &Path) -> Result<(), Self::CreateProjectError> {
        std::fs::create_dir_all(path)?;

        for entry in self.folder.read_dir()? {
            let entry = entry?;
            let entry_name = entry.file_name();

            if entry_name.as_encoded_bytes() == RUNTIME_TEMPLATE_FNAME {
                continue;
            }

            let entry_path = entry.path();
            crate::io_methods::non_recursively_copy_contents_of_directory_with_fancy_tui_progressbar(entry_path, path)?;
        }

        Ok(())
    }
}

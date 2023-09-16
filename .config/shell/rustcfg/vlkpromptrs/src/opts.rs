use std::{
    error::Error,
    io,
    env,
    fs,
    rc::Rc,
    process,
};

const SGR: &str = "%k%f%b%u%s";

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum DirType {
    Cwd,
    Git,
    Vim,
}

#[derive(Debug, PartialEq, Clone, Copy)]
pub struct Color {
    pub int: u8,
}
impl Color {
    // pub fn color_bg(&self) -> String {
    //     format!("%K{{{}}}", self.int)
    // }
    pub fn color_bg(&self) -> String { format!("%K{{{}}}", self.int) }
    pub fn color_fg(&self) -> String { format!("%F{{{}}}", self.int) }
}

#[derive(Debug, PartialEq, Clone)]
pub struct Module {
    pub icon: String,
    pub color: Color,
    pub textcolor: Color,
    pub content: String,
    pub end_icon: String,
}
impl Module {
    pub fn format(&self, next_color: &Color) -> String {
        format!("{}{}{}%B{} {} {}{}{}{}{}",
            SGR,
            self.color.color_bg(),
            self.textcolor.color_fg(),
            self.icon,
            self.content,
            SGR,
            self.color.color_fg(),
            next_color.color_bg(),
            self.end_icon,
            SGR
        )
    }
}

pub fn generate_config() -> Result<(), Box<dyn Error>> {

    let has_sudo = !env::var("VLKPROMPT_SUDO").unwrap().is_empty();
    let has_git = !env::var("VLKPROMPT_GIT").unwrap().is_empty();
    let has_vim = !env::var("VLKPROMPT_VIM").unwrap().is_empty();
    let has_jobs = !env::var("VLKPROMPT_JOBS").unwrap().is_empty();

    let errors = env::var("VLKPROMPT_ERR").unwrap().parse::<u16>().unwrap_or(42069);

    let cwd = env::current_dir()?;
    let cwd_writable = !fs::metadata(cwd)?.permissions().readonly();

    let mut modules: Vec<Module> = Vec::new();

    println!("{}", cwd_writable);

    Ok(())
}


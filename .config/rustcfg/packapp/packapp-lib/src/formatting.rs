#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
pub enum ColorType {
    None,
    Color16,
    Color256,
    TrueColor,
}

#[derive(Debug, Clone, Copy)]
pub struct Color {
    pub foreground: Option<u8>,
    pub background: Option<u8>,
    pub bold: bool,
    pub dim: bool,
}
impl Default for Color {
    fn default() -> Self {
        Self {
            foreground: None,
            background: None,
            bold: false,
            dim: false,
        }
    }
}
impl Color {
    pub fn new() -> Self {
        Color::default()
    }
    pub fn bg(&mut self, color: Option<u8>) -> Self {
        self.background = color;
        *self
    }
    pub fn fg(&mut self, color: Option<u8>) -> Self {
        self.foreground = color;
        *self
    }
    pub fn bold(&mut self, set: bool) -> Self {
        self.bold = set;
        *self
    }
    pub fn dim(&mut self, set: bool) -> Self {
        self.dim = set;
        *self
    }
    pub fn ansi_string(&self) -> String {
        let mut fmt_vec: Vec<u8> = Vec::new();
        if self.bold {
            fmt_vec.push(1);
        }
        if self.dim {
            fmt_vec.push(2);
        }
        if let Some(fg) = self.foreground {
            // let tmpcolor = format!("38;5;{}", self.foreground);
            fmt_vec.push(38);
            fmt_vec.push(5);
            fmt_vec.push(fg);
        }
        if let Some(bg) = self.background {
            // let tmpcolor = format!("48;5;{}", self.background);
            fmt_vec.push(48);
            fmt_vec.push(5);
            fmt_vec.push(bg);
        }
        if fmt_vec.is_empty() {
            "".to_owned()
        } else {
            format!(
                "\x1b[{}m",
                fmt_vec
                    .iter()
                    .map(|i| i.to_string())
                    .collect::<Vec<String>>()
                    .join(";")
            )
        }
    }
}

pub fn powerline_fmt(
    color: Color,
    inherits_ansi: bool,
    powerline_icon: &str,
    text: &str,
    next_color: Option<Color>,
) -> String {
    let my_color = if inherits_ansi {
        "".to_owned()
    } else {
        color.ansi_string()
    };

    let end_color;
    let end_addenum;
    if let Some(mut next) = next_color {
        end_color = Color::new().bg(next.background).fg(color.background);
        end_addenum = next.bg(None).ansi_string();
    } else {
        end_color = Color::new().fg(color.background);
        end_addenum = "\x1b[0m".to_string()
    }
    format!(
        "{} {} \x1b[0m{}{}{}",
        my_color,
        text,
        end_color.ansi_string(),
        powerline_icon,
        end_addenum
    )
}

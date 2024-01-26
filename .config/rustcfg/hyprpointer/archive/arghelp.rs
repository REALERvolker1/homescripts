pub trait ArgValue: fmt::Debug + Send + Sized + fmt::Display {}
pub trait ArgValueEnum: ArgValue + strum::EnumMessage {}

/// A help message. This contains a lot of performance overhead, so only use it in helptext.
#[derive(Debug)]
pub struct ArgHelp<F, E, T>
where
    F: ArgFlag,
    T: ArgValue,
    E: ArgValueEnum,
{
    flag: F,
    message: String,
    detailed_message: Option<String>,
    default_value: Option<T>,
    available_values: Option<Vec<E>>,
}
impl<F, E, T> ArgHelp<F, E, T>
where
    F: ArgFlag,
    T: ArgValue,
    E: ArgValueEnum,
{
    pub fn new(
        flag: F,
        message: String,
        detailed_message: Option<String>,
        default_value: Option<T>,
        available_values: Option<Vec<E>>,
    ) -> Self {
        Self {
            flag,
            message,
            detailed_message,
            default_value,
            available_values,
        }
    }
    pub fn format_short(&self) -> String {
        if let Some(d) = &self.default_value {
            format!("{}{}", self.message, d)
        } else {
            self.message.clone()
        }
    }
    pub fn format_detailed(&self) -> String {
        let my_flag = format!("\x1b[1m{}\x1b[0m", &self.flag);
        let my_detail_opt = if let Some(s) = &self.detailed_message {
            Some(s.as_str())
        } else {
            None
        };

        let myself_fmt =
            Self::def_fmt_detail_strings(&my_flag, 0, Some(&self.message), my_detail_opt);

        let detail_format = if let Some(d) = &self.default_value {
            let default_val_fmt = format!("Default value: \x1b[1m{}\x1b[0m", d);

            Some(if let Some(avail) = &self.available_values {
                default_val_fmt + "\n\nAvailable values:\n" + &Self::def_avail(avail)
            } else {
                default_val_fmt
            })
        } else {
            None
        };
        if let Some(d) = detail_format {
            myself_fmt + "\n" + &d
        } else {
            myself_fmt
        }
    }
    /// This will print strings in the format:
    ///
    /// ```text
    /// mandatory text    short text
    ///
    /// detailed text
    /// some more detailed text
    /// ````
    fn def_fmt_detail_strings(
        mandatory_text: &str,
        max_width: usize,
        short_text: Option<&str>,
        detail_text: Option<&str>,
    ) -> String {
        if let Some(message) = short_text {
            let message_format = format!("{:max_width$}  {}", mandatory_text, message);
            if let Some(detailed_message) = detail_text {
                // String with detailed messages and whatnot
                // format!("{message_format}\n{detailed_message}\n")
                message_format + "\n" + detailed_message + "\n"
            } else {
                // Just the short message
                message_format
            }
        } else {
            mandatory_text.to_owned()
        }
    }
    // fn def_fmt<'a>(default: &T) -> fmt::Arguments<'a> {
    //     format_args!("Default value: \x1b[1m{}\x1b[0m", default)
    // }
    /// Returns a string with all the available enum options. For use in long help.
    fn def_avail(available: &Vec<E>) -> String {
        let vals = available
            .iter()
            .map(|v| {
                (
                    format!("\x1b[1m{}\x1b[0m", &v),
                    v.get_message(),
                    v.get_detailed_message(),
                )
            })
            .collect::<Vec<_>>();

        // It doesn't matter if this counts the formatting or not, I just want to pad it all evenly.
        let max_width = vals
            .iter()
            .map(|v| UnicodeWidthStr::width(v.0.as_str()))
            .max()
            .unwrap_or(0);

        let options = vals
            .into_iter()
            .map(|(text, msg_opt, detailed_message_option)| {
                Self::def_fmt_detail_strings(&text, max_width, msg_opt, detailed_message_option)
            })
            .collect::<Vec<_>>();

        options.join("\n")
    }
}

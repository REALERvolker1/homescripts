use log::debug;
use skim::prelude::*;
use smart_default::SmartDefault;
use std::collections::HashMap;

/// TODO: Unfuck this entire struct
#[derive(Debug, Clone, SmartDefault)]
pub struct SearchItem {
    /// The display text of the item
    #[default = "<None>"]
    text: String,
    /// The text of the item, formatted with the query
    #[default = "No Preview Available"]
    preview_text: String,
    // package: raur::Package,
}
impl SearchItem {
    // pub fn from_package(package: &raur::Package) -> Self {
    //     let name_fmt = format!("{:<30}", &package.name);
    //     Self {
    //         text: package.name.clone(),
    //         query: None,
    //         queryfmtstr: Some(name_fmt),
    //     }
    // }
    pub fn from_package(package: &raur::Package) -> Self {
        let text = format!("{:<30}", package.name);
        // let fmt_query = format!("\x1b[1m{}\x1b[0m", query);
        // let fmt_name = format!("{:<30}\x1b[0m", &name.replace(query, &fmt_query));
        // let preview_text = format!("name: {}\nversion: {}\nVotes: {}, Popularity: {}\nSource: {}{}", package.name, package.version, package.description, package.num_votes, package.popularity, package.);
        let preview_text = format!("{:#?}", package);
        debug!("Search item from: {:?}", &package);
        Self { text, preview_text }
    }
    // pub fn from_str(text: &str) -> Self {
    //     Self {
    //         text: text.to_owned(),
    //         query: None,
    //         queryfmtstr: None,
    //     }
    // }
}
impl SkimItem for SearchItem {
    fn text(&self) -> Cow<str> {
        Cow::Borrowed(&self.text)
    }

    fn preview(&self, _context: PreviewContext) -> ItemPreview {
        // ItemPreview::Text(self.text.to_owned())
        ItemPreview::AnsiText(self.preview_text.clone())
    }
}

pub fn select_from_list<T>(list: T) -> eyre::Result<Vec<String>>
where
    T: Iterator<Item = SearchItem>,
{
    let skim_options = SkimOptionsBuilder::default()
        // .height(Some("50%"))
        .multi(true)
        .regex(true)
        .preview(Some(""))
        .build()?;

    // Skim has an asinine API, so we have to use a channel
    let (tx, rx): (SkimItemSender, SkimItemReceiver) = unbounded();
    if log::log_enabled!(log::Level::Debug) {
        for item in list {
            if let Err(r) = tx.send(Arc::new(item)) {
                debug!("Error sending item to Skim: {:?}", r);
            }
        }
    } else {
        for item in list {
            tx.send(Arc::new(item)).unwrap_or_default();
        }
    }
    drop(tx);

    println!("\x1b[0m");

    let selected = Skim::run_with(&skim_options, Some(rx))
        .map(|out| out.selected_items)
        .unwrap_or_else(Vec::new)
        .iter()
        .map(|i| i.text().trim().to_string())
        .collect::<Vec<String>>();
    // .filter_map(|selected_item| (**selected_item).as_any().downcast_ref::<SearchItem>())
    // .map(|i| i.to_owned())
    // .collect::<Vec<SearchItem>>();

    println!("\x1b[0m");

    for item in selected.iter() {
        println!("'{}'", &item);
    }

    Ok(selected)
}

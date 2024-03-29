use crate::{entry::Entry, undef};

pub fn get_term() -> Entry {
    let term = undef!(@err std::env::var("TERM"), "Term");
    Entry::new("Term", term)
}

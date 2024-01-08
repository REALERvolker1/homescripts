use termion;
use std::{env, path::*, io};
use crate::*;

#[derive(Debug)]
pub struct TermProps {
    pub rows: usize,
    pub columns: usize,
}
impl TermProps {
    pub fn new() -> Self {
        let (columns, rows) = termion::terminal_size().unwrap_or((u16::MAX, u16::MAX));

        Self {
            rows: rows as usize,
            columns: columns as usize,
        }
    }
}

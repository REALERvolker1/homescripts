use crate::io_methods::isatty;
use std::io::Read;

type TerminalDimensionRepr = u16;
type PackedTerminalDimensionRepr = u32;

const TERMINAL_DIMENSION_REPR_BITSIZE: PackedTerminalDimensionRepr =
    (size_of::<TerminalDimensionRepr>() * 8) as PackedTerminalDimensionRepr;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
struct TerminalDimension(TerminalDimensionRepr);
impl TerminalDimension {
    pub const fn from_raw(raw: TerminalDimensionRepr) -> Self {
        Self(raw)
    }
    pub const fn to_raw(self) -> TerminalDimensionRepr {
        self.0
    }
}

/// rows
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct TerminalHeight(TerminalDimension);
impl TerminalHeight {
    pub const fn from_raw(raw: TerminalDimensionRepr) -> Self {
        Self(TerminalDimension::from_raw(raw))
    }
    pub const fn to_raw(self) -> TerminalDimensionRepr {
        self.0.to_raw()
    }
}
/// cols
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct TerminalWidth(TerminalDimension);
impl TerminalWidth {
    pub const fn from_raw(raw: TerminalDimensionRepr) -> Self {
        Self(TerminalDimension::from_raw(raw))
    }
    pub const fn to_raw(self) -> TerminalDimensionRepr {
        self.0.to_raw()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct TermRect {
    pub rows: TerminalHeight,
    pub cols: TerminalWidth,
}
impl TermRect {
    pub const fn new(rows: TerminalHeight, cols: TerminalWidth) -> Self {
        Self { rows, cols }
    }
    pub const fn new_from_raw(rows: TerminalDimensionRepr, cols: TerminalDimensionRepr) -> Self {
        Self {
            rows: TerminalHeight::from_raw(rows),
            cols: TerminalWidth::from_raw(cols),
        }
    }
    pub const fn new_from_packed(packed: PackedTerminalDimensionRepr) -> Self {
        Self {
            rows: TerminalHeight::from_raw(
                (packed >> TERMINAL_DIMENSION_REPR_BITSIZE) as TerminalDimensionRepr,
            ),
            cols: TerminalWidth::from_raw(packed as TerminalDimensionRepr),
        }
    }
    pub const fn pack(self) -> PackedTerminalDimensionRepr {
        let shifted =
            (self.rows.to_raw() as PackedTerminalDimensionRepr) << TERMINAL_DIMENSION_REPR_BITSIZE;

        shifted | self.cols.to_raw() as PackedTerminalDimensionRepr
    }
}

pub struct TuiWidget {
    pub width: TerminalWidth,
    pub height: TerminalHeight,
}

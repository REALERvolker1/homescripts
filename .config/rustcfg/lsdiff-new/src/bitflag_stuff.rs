use ::std::fs::Metadata;

pub type BitflagThingy = u8;

const PK_OFFSET_DIR: usize = 0;
const PK_OFFSET_LINK: usize = 1;
const PK_OFFSET_HIDDEN: usize = 2;
const PK_OFFSET_CACHED: usize = 3;
// const PK_OFFSET_ERROR: usize = 4;

pub const PK_IS_DIR: u8 = 1 << PK_OFFSET_DIR;
pub const PK_IS_LINK: u8 = 1 << PK_OFFSET_LINK;
pub const PK_IS_HIDDEN: u8 = 1 << PK_OFFSET_HIDDEN;
pub const PK_IS_CACHED: u8 = 1 << PK_OFFSET_CACHED;

pub const PK_BITMASK_NOCACHE: u8 = PK_IS_DIR | PK_IS_LINK | PK_IS_HIDDEN;
pub const PK_BITMASK: u8 = PK_BITMASK_NOCACHE | PK_IS_CACHED;

// pub const PK_IS_ERROR: u8 = 1 << PK_OFFSET_ERROR; // PK_IS_DIR | PK_IS_LINK | PK_IS_HIDDEN | PK_IS_REMOVED + 1;

const PK_LINK_ICON_ARRAY: [char; 4] = ['󱅷', '󰾶', '󱅸', '󰾷'];

pub const PK_ICON_ARRAY: [char; (PK_BITMASK + 2) as usize] = [
    '󰈙',
    '',
    PK_LINK_ICON_ARRAY[0],
    PK_LINK_ICON_ARRAY[1],
    '󰷊',
    '󱞊',
    PK_LINK_ICON_ARRAY[0],
    PK_LINK_ICON_ARRAY[1],
    '󰧮',
    '󰉖',
    PK_LINK_ICON_ARRAY[0b10],
    PK_LINK_ICON_ARRAY[0b11],
    '󰷋',
    '󱞋',
    PK_LINK_ICON_ARRAY[0b10],
    PK_LINK_ICON_ARRAY[0b11],
    '󱪠',
];

/// Warning: Does not detect if the file name starts with a dot
#[inline(always)]
pub fn kind_for_metadata(metadata: &Metadata) -> u8 {
    (metadata.is_dir() as u8) << PK_OFFSET_DIR | (metadata.is_symlink() as u8) << PK_OFFSET_LINK
}

#[inline(always)]
pub fn kind_for_metadata_with_name(metadata: &Metadata, name: &[u8]) -> u8 {
    (metadata.is_dir() as u8) << PK_OFFSET_DIR
        | (metadata.is_symlink() as u8) << PK_OFFSET_LINK
        | ((!name.is_empty() && name[0] == b'.') as u8) << PK_OFFSET_HIDDEN
}

// use ::arrayvec::ArrayVec;

// const ENTRY_SIZE: usize = 64;

// const MAX_ENTRY_LEN: usize =
//     ENTRY_SIZE - (size_of::<&'static EntryMetadata>() + size_of::<ArrayVec<(), 0>>());

pub struct EntryMetadata {
    pub color: u8,
    pub name: &'static str,
    pub icon: char,
}

// pub struct Entry {
//     pub meta: &'static EntryMetadata,
//     pub data: ArrayVec<u8, MAX_ENTRY_LEN>,
// }
// impl Entry {
//     // pub fn print(&self)
// }

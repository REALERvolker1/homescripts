use ::arrayvec::ArrayVec;

const MAX_ENTRY_LEN: usize = 48;

pub struct Entry {
    pub key: &'static str,
    pub data: ArrayVec<u8, MAX_ENTRY_LEN>,
    pub icon: char,
}
impl Entry {
    pub const fn new(key: &'static str, icon: char) -> Self {
        Self {
            key,
            data: ArrayVec::new_const(),
            icon,
        }
    }
    // pub fn append_to_buffer<const N: usize>(&mut self, buf: &mut ArrayVec<u8, N>) {}
}

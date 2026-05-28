use ::core::{
    ffi::{CStr, c_char, c_int},
    marker::PhantomData,
    num::NonZero,
    ptr::NonNull,
};

/// The `argc` and `argv` from [`main`](crate::main), packaged as an iterator
#[derive(Debug, Clone)]
pub struct ArgIter {
    argv: NonNull<*mut c_char>,
    argc: NonZero<c_int>,
    i: c_int,
    /// Here to uphold the !Send invariant
    _marker: PhantomData<&'static *const ()>,
}
impl ArgIter {
    /// # Safety
    ///
    /// This is only safe to call from `main` or from a known-good reference to
    /// the program's arguments.
    ///
    /// This is **NOT THREADSAFE**.
    #[inline]
    #[must_use]
    pub unsafe fn new(argc: c_int, argv: *mut *mut c_char) -> Option<Self> {
        let argv = NonNull::new(argv)?;
        let argc = NonZero::new(argc)?;
        Some(Self {
            argv,
            argc,
            i: 0,
            _marker: PhantomData,
        })
    }
}
impl Iterator for ArgIter {
    /// # Safety
    /// The process's CLI args are OS-provided and are guaranteed to be static as
    /// long as nobody mutates them. The caller guarantees this is called with
    /// process args, we guarantee it is !Send
    type Item = &'static CStr;
    fn next(&mut self) -> Option<Self::Item> {
        if self.i >= self.argc.get() {
            return None;
        }

        let count = self.i as _;
        let current = *unsafe { self.argv.offset(count).as_ref() };

        if current.is_null() {
            self.i = c_int::MAX;
            return None;
        }
        self.i += 1;
        // SAFETY: The OS and us upheld all necessary invariants, and we checked for nulls
        Some(unsafe { CStr::from_ptr(current) })
    }
    fn size_hint(&self) -> (usize, Option<usize>) {
        let sz = self.len();
        (sz, Some(sz))
    }
}
impl ExactSizeIterator for ArgIter {
    fn len(&self) -> usize {
        self.argc.get().saturating_sub(self.i) as _
    }
}

// #[inline]
// #[must_use]
// pub unsafe fn cli_argv_iter(argc: c_int, argv: NonNull<*mut c_char>) -> impl Iterator<Item = &'static CStr>

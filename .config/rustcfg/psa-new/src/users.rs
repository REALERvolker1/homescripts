use ahash::HashSetExt;
use nu_ansi_term::AnsiGenericString;

use crate::*;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, strum_macros::Display)]
pub enum Action {
    Print,
    Pidstat,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, strum_macros::Display)]
pub enum UserType {
    Myself,
    Other,
    Root,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TrackedUser {
    pub user: User,
    pub user_type: UserType,
    pub style: Style,
}
impl TrackedUser {
    pub fn from_uid(uid: Uid, my_uid: Uid) -> Bruh<Option<Self>> {
        let user = if let Some(u) = User::from_uid(uid)? {
            u
        } else {
            return Ok(None);
        };

        let base_style = Style::new().bold();
        let (user_type, style) = match uid {
            my_uid => (UserType::Myself, base_style.fg(Color::LightGreen)),
            unistd::ROOT => (UserType::Root, base_style.fg(Color::LightRed)),
            _ => (UserType::Other, base_style.fg(Color::LightCyan)),
        };

        Ok(Some(Self {
            user,
            user_type,
            style,
        }))
    }
    /// Returns a string like `username (UID)`
    pub fn format_self<'a>(&'a self) -> AnsiGenericString<'a, str> {
        self.style
            .paint(format!("{} ({})", self.user.name, self.user.uid))
    }
}
impl fmt::Display for TrackedUser {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "User: {} ({})
User Type: {}
Home: {}
Shell: {}",
            self.user.name,
            self.user.uid,
            self.user_type,
            self.user.dir.display(),
            self.user.shell.display()
        )
    }
}

#[derive(Debug)]
pub struct UserCache {
    inner: HashMap<Uid, Arc<TrackedUser>>,
    nonexistent: HashSet<Uid>,
}
impl Default for UserCache {
    fn default() -> Self {
        Self {
            inner: HashMap::new(),
            nonexistent: HashSet::new(),
        }
    }
}
impl UserCache {
    pub fn new_with_uids<I>(uid_iter: I) -> Self
    where
        I: Iterator<Item = Uid>,
    {
        let mut me = Self::default();
        me.insert_uids(uid_iter);
        me
    }
    pub fn insert_uids<I>(&mut self, uid_iter: I)
    where
        I: Iterator<Item = Uid>,
    {
        for uid in uid_iter.unique() {
            self.insert_user_uid(uid);
        }
    }
    pub fn get_user(&self, uid: Uid) -> Option<Arc<TrackedUser>> {
        self.inner.get(&uid).cloned()
    }
    pub fn insert_user_uid(&mut self, uid: Uid) {
        if let Ok(Some(u)) = TrackedUser::from_uid(uid, *MY_UID) {
            self.inner.insert(uid, Arc::new(u));
        } else {
            self.nonexistent.insert(uid);
        }
    }
}
impl fmt::Display for UserCache {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let fail_len = self.nonexistent.len();
        let failed_uuid_string = if fail_len > 0 {
            format!("\nUids failed: {}\n{:?}", fail_len, self.nonexistent.iter())
        } else {
            String::new()
        };

        write!(
            f,
            "Uids found: {}{}
Users:
{}",
            self.inner.len(),
            failed_uuid_string,
            self.inner.values().map(|u| u.to_string()).join("\n\n")
        )
    }
}

// I don't want dependencies
// /// Very inefficient. Nested nested loops over Vecs. Don't throw a ton of stuff into here.
// pub fn check_path(binaries: &[&str]) -> Bruh<HashMap<String, bool>> {
//     // let mut to_check = binaries.into_iter().collect_vec();

//     let mut to_check = HashMap::new();
//     for b in binaries {
//         to_check.insert(b.to_string(), false);
//     }

//     env::var("PATH")?
//         .split(":")
//         .unique()
//         .map(|p| Path::new(p))
//         .filter(|p| p.is_dir())
//         .for_each(|p| {
//             let dir_read = if let Ok(r) = p.read_dir() {
//                 r
//             } else {
//                 return;
//             };

//             // Loop over the dir contents
//             let _ = dir_read.filter_map(|f| f.ok()).for_each(|p| {
//                 let file_name = p.file_name();
//                 let key = if let Some(s) = file_name.to_str() {
//                     s
//                 } else {
//                     return;
//                 };

//                 if to_check.contains_key(key) {
//                     to_check.insert(String::from(key), true);
//                 }
//             });
//         });

//     Ok(to_check)
// }

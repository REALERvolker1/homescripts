use ahash::HashSetExt;

use crate::*;

// #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
// pub enum UserGroup {
//     Real(Uid),
//     /// The Real UID and Effective UID, in order.
//     RealEffective(Uid, Uid),
// }
// impl UserGroup {
//     pub fn get<'a>(&'a self) -> (Uid, Option<Uid>) {
//         match *self {
//             Self::Real(u) => (u, None),
//             Self::RealEffective(u, e) => (u, Some(e)),
//         }
//     }
//     pub fn format_uid(&self, user_cache: users::UserCache) -> String {
//         match *self {
//             Self::Real(u) => {
//                 if let Some(user) = user_cache.get_user(u) {
//                     user.format_self().to_string()
//                 } else {
//                     Color::LightRed
//                         .bold()
//                         .paint(format!("Unable to find user: {u}"))
//                         .to_string()
//                 }
//             }
//             Self::RealEffective(u, e) => match (user_cache.get_user(u), user_cache.get_user(e)) {
//                 (Some(real_user), Some(effective_user)) => {
//                     format!(
//                         "Real user: {}, effective user: {}",
//                         real_user.format_self(),
//                         effective_user.format_self()
//                     )
//                 }
//                 (Some(real_user), None) => {
//                     format!(
//                         "Real user: {}, EUID not found: {e}",
//                         real_user.format_self(),
//                     )
//                 }
//                 (None, Some(effective_user)) => {
//                     format!(
//                         "Effective user: {}, RUID not found: {u}",
//                         effective_user.format_self(),
//                     )
//                 }
//                 (None, None) => Color::LightRed
//                     .bold()
//                     .paint(format!("RUID ({u}) and EUID ({e}) not found"))
//                     .to_string(),
//             },
//         }
//     }
// }

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
    pub fn from_uid(uid: Uid) -> Bruh<Self> {
        let user = match User::from_uid(uid.into()) {
            Ok(Some(u)) => u,
            _ => return Err(BruhMoment::InvalidUser(uid)),
        };

        let base_style = Style::new().bold();

        // the bastards wouldn't let me use a match statement
        let (user_type, style) = if uid == *MY_UID {
            (UserType::Myself, base_style)
        } else if uid == ROOT_UID {
            (UserType::Root, base_style)
        } else {
            (UserType::Other, base_style)
        };

        Ok(Self {
            user,
            user_type,
            style,
        })
    }
    /// Returns a string like `username (UID)`
    pub fn format_self<'a>(&'a self) -> style::StyledContent<String> {
        self.style
            .apply(format!("{} ({})", self.user.name, self.user.uid))
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
        if let Ok(u) = TrackedUser::from_uid(uid) {
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

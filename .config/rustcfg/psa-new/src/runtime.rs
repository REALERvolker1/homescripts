use crate::*;

/// Here so I can do interior mutability and pass around some shared data at startup.
#[derive(Debug, Default)]
pub struct GodObject {
    pub user_cache: users::UserCache,
    pub process_cache: processes::ProcInfoCache,
}
impl fmt::Display for GodObject {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "User cache details:\n{}\nProcess cache details:\n{}",
            self.user_cache, self.process_cache
        )
    }
}
impl GodObject {
    pub fn new() -> Bruh<Self> {
        let mut me = Self::default();
        me.update()?;
        debug!("{me}");
        Ok(me)
    }
    pub fn update(&mut self) -> Bruh<()> {
        debug!("Updating process cache...");
        let procs = processes::ProcInfoCache::get_procs()?;

        let unique_uids = procs
            .iter()
            .map(|p| p.users().get().into_vec())
            .flatten()
            .unique();

        self.user_cache.insert_uids(unique_uids);
        self.process_cache.refresh_with_procs(procs.into_iter());

        Ok(())
    }
}

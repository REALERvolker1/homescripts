use super::*;
use size::Size;
use sysinfo::Disks;

#[derive(Debug, Clone, Copy, SmartDefault, Deserialize, Serialize)]
pub struct DiskConfig {
    /// The poll rate, in seconds
    #[default = 120]
    pub poll_rate: u64,
}

#[derive(Debug)]
pub struct DiskModule {
    poll_rate: Duration,
    disks: Disks,
}
impl Module for DiskModule {
    type StartupData = DiskConfig;
    async fn new(data: Self::StartupData) -> ModResult<(Self, ModuleData)> {
        let mut me = Self {
            poll_rate: Duration::from_secs(data.poll_rate),
            disks: Disks::new(),
        };
        let my_data = me.update();
        Ok((me, my_data))
    }

    async fn run(&mut self, sender: ModuleSender) -> ModResult<()> {
        loop {
            let poll = join!(sleep!(self.poll_rate), sender.send(self.update()));
            poll.1?;
        }
    }
}
impl DiskModule {
    pub fn update(&mut self) -> ModuleData {
        self.disks.refresh_list();
        DiskList::from_disk_list(&self.disks).into()
    }
}

#[derive(Debug, derive_more::From)]
pub struct DiskList(HashSet<Disk>);
impl DiskList {
    pub fn from_disk_list(disks: &Disks) -> Self {
        disks
            .iter()
            .map(|d| Disk::from_disk(d))
            .collect::<HashSet<Disk>>()
            .into()
    }
}
impl fmt::Display for DiskList {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0
            .iter()
            .map(|d| d.to_string())
            .collect_vec()
            .join("\n")
            .fmt(f)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Disk {
    pub total: u64,
    pub used: u64,
    pub percent: Percent,
}
impl Disk {
    pub fn from_disk(disk: &sysinfo::Disk) -> Self {
        let total_space = disk.total_space();
        let avail = disk.available_space();
        let used = total_space - avail;

        Self {
            total: total_space,
            used: used,
            percent: Percent::of_numbers(used, total_space),
        }
    }
}
impl fmt::Display for Disk {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{} / {} ({})",
            Size::from_bytes(self.used),
            Size::from_bytes(self.total),
            self.percent
        )
    }
}

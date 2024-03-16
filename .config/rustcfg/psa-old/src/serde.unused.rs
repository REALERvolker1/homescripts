/*
from main.rs

/// The preview window preview command, using a cachefile that shows a snapshot of the machine state
///
/// as it was when the program started running
fn show_preview_window(fzf_output: &str) -> Result<(), procinfo::ProcError> {
    let mut serde_reader = command::SerdeReader::new_empty()?;
    serde_reader.from_file()?;
    if let Some(pid) = command::get_pid_from_fzf_output(fzf_output) {
        if let Some(proc) = serde_reader.get_process_by_pid(pid) {
            println!("{}", proc.info_style());
            return Ok(());
        }
    }
    Err(procinfo::ProcError::CustomError(
        "Could not find process!".to_owned(),
    ))
}

    // Make a new SerdeReader with the processes
    // let serde_reader = command::SerdeReader::new_with_procs(processes)?;
    // put everything into a file for this program to read
    // serde_reader.to_file()?;

        // remove the tmpfile
    // serde_reader.cleanup()?;
*/

/// The way this program passes data to the fzf window is by serializing and deserializing data from a file.
///
/// This is the struct that does that.
pub struct SerdeReader {
    pub processes: Vec<proc::Proc>,
    pub filepath: PathBuf,
}
impl SerdeReader {
    /// Do this if in the window function.
    pub fn new_empty() -> Result<Self, procinfo::ProcError> {
        Self::new_with_procs(Vec::new())
    }
    /// Only do this in the main function when you have all the processes
    pub fn new_with_procs(processes: Vec<proc::Proc>) -> Result<Self, procinfo::ProcError> {
        let path_string = env::var("XDG_RUNTIME_DIR").unwrap_or("/tmp".to_string());
        let dir_path = Path::new(&path_string);

        // make sure it exists and I can write to it
        if !dir_path.exists() {
            fs::create_dir_all(dir_path)?;
        }
        if !dir_path.is_dir() || dir_path.metadata()?.permissions().readonly() {
            return Err(procinfo::ProcError::CustomError(
                "Invalid directory!".to_owned(),
            ));
        }
        // join filepath, but don't do anything with that yet.
        let filepath = dir_path.join("cache.json");

        Ok(Self {
            processes,
            filepath: filepath,
        })
    }
    /// Removes the cachefile because that's in tmpfs and wasting ram
    pub fn cleanup(self) -> io::Result<()> {
        if self.filepath.exists() {
            fs::remove_file(&self.filepath)?;
        }
        Ok(())
    }
    /// serialize into a file so I can cache the output for the fzf view screen
    pub fn to_file(&self) -> io::Result<()> {
        // cleanup function was probably skipped.
        if self.filepath.exists() {
            fs::remove_file(&self.filepath)?;
        }
        let mut file = io::BufWriter::new(fs::File::create(&self.filepath)?);
        serde_json::to_writer(&mut file, &self.processes)?;
        Ok(())
    }
    /// reads processes from a file and mutates self. Please access results from self.processes
    pub fn from_file(&mut self) -> Result<(), procinfo::ProcError> {
        let reader = io::BufReader::new(fs::File::open(&self.filepath)?);
        self.processes = serde_json::from_reader(reader)?;
        Ok(())
    }

    pub fn get_process_by_pid(&self, pid: i32) -> Option<proc::Proc> {
        if let Some(process) = self.processes.iter().find(|p| p.pid == pid) {
            Some(process.to_owned())
        } else {
            None
        }
    }
}

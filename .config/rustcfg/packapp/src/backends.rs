use std::io;
use tokio::process;

use which;

#[derive(Debug, Clone, Copy)]
pub enum AvailableBackend {
    Pacman,
    Dnf,
    Undefined,
}

fn get_distpkg_backend() -> AvailableBackend {
    let mut backend = "";
    for i in ["dnf", "pacman"] {
        if let Ok(cmdpath) = which::which(i) {
            backend = i;
            break;
        }
    }
    match backend {
        "dnf" => AvailableBackend::Dnf,
        "pacman" => AvailableBackend::Pacman,
        _ => AvailableBackend::Undefined,
    }
}

#[derive(Debug, Clone)]
pub struct Package {
    pub repo: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub arch: String,
    pub url: String,
    pub license: String,
}

#[derive(Debug, Clone)]
pub struct Backend {
    pub backend_type: AvailableBackend,
    pub packages: Vec<Package>,
    pub installed: Vec<Package>,
}
impl Backend {
    pub async fn new_with_backend(backend: AvailableBackend) -> Option<Self> {
        let (command_str, args) = match backend {
            AvailableBackend::Dnf => ("dnf", vec!["--help"]),
            AvailableBackend::Pacman => ("pacman", vec!["-Si", "--color", "never"]),
            _ => ("", Vec::new()),
        };
        if let Ok(output) = get_cmd_output(command_str, args).await {
            let mut packages = Vec::new();
            let mut installed = Vec::new();

            match backend {
                AvailableBackend::Dnf => {}
                AvailableBackend::Pacman => {
                    for i in output.iter() {
                        if i.starts_with(" ") || i.is_empty() {
                            continue;
                        }

                        // let i_colon = i.find(":");
                        // if let Some(colon) = i_colon {
                        //     let (key, val) = i.split_at(colon);
                        // }
                    }
                }
                _ => {}
            }

            Some(Self {
                backend_type: backend,
                packages: packages,
                installed: installed,
            })
        } else {
            return None;
        }
    }
    pub async fn new() -> Option<Self> {
        let backend = get_distpkg_backend();
        Self::new_with_backend(backend).await
    }
}

async fn get_cmd_output(command: &str, args: Vec<&str>) -> Result<Vec<String>, io::Error> {
    let output = process::Command::new(command).args(args).output().await?;
    // let output = command.wait_with_output().await?;
    let stdout = String::from_utf8(output.stdout).unwrap();
    let stdoutvec: Vec<String> = stdout.lines().map(|i| i.to_string()).collect();
    Ok(stdoutvec)
}

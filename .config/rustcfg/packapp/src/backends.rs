use std::io;
use tokio::process;

use sqlx::FromRow;
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

#[derive(Debug, Clone, FromRow)]
pub struct Package {
    pub repo: String,
    pub name: String,
    pub version: String,
    pub description: String,
}

#[derive(Debug, Clone)]
pub struct Backend {
    pub backend_type: AvailableBackend,
    pub packages: Vec<Package>,
    pub installed: Vec<Package>,
}
impl Backend {
    pub async fn new(backend_or_none: Option<AvailableBackend>) -> Result<Self, io::Error> {
        let backend = match backend_or_none {
            Some(_) => backend_or_none.unwrap(),
            None => get_distpkg_backend(),
        };

        let (all_command_str, all_args, inst_args) = match backend {
            AvailableBackend::Dnf => ("dnf", vec!["list"], vec!["list --installed"]),
            AvailableBackend::Pacman => (
                "pacman",
                vec!["-Si", "--color", "never"],
                vec!["-Qi", "--color", "never"],
            ),
            _ => ("", Vec::new(), Vec::new()),
        };
        let all_output = get_cmd_output(all_command_str, all_args).await?;
        let inst_output = get_cmd_output(all_command_str, inst_args).await?;

        let packages = match backend {
            AvailableBackend::Dnf => dnf_parse(all_output),
            AvailableBackend::Pacman => pacman_parse(all_output),
            _ => Vec::new(),
        };
        let installed = match backend {
            AvailableBackend::Dnf => dnf_parse(inst_output),
            AvailableBackend::Pacman => pacman_parse(inst_output),
            _ => Vec::new(),
        };
        Ok(Self {
            backend_type: backend,
            packages: packages,
            installed: installed,
        })
    }
}

async fn get_cmd_output(command: &str, args: Vec<&str>) -> Result<Vec<String>, io::Error> {
    let output = process::Command::new(command).args(args).output().await?;
    // let output = command.wait_with_output().await?;
    let stdout = String::from_utf8(output.stdout).unwrap();
    let stdoutvec: Vec<String> = stdout.lines().map(|i| i.to_string()).collect();
    Ok(stdoutvec)
}

fn dnf_parse(command_output: Vec<String>) -> Vec<Package> {
    Vec::new()
}

fn pacman_parse(command_output: Vec<String>) -> Vec<Package> {
    let mut packages = Vec::new();
    let mut repo = "";
    let mut name = "";
    let mut version = "";
    let mut description = "";
    for i in command_output.iter() {
        if i.starts_with(" ") || i.is_empty() {
            continue;
        }
        if let Some(colon) = i.find(":") {
            let (key, val) = i.split_at(colon + 1);
            // key.replacen(":", "", 1);
            let strip_key = key.replace(" ", "");
            match strip_key.as_str() {
                "Repository:" => repo = val,
                "Name:" => name = val,
                "Version:" => version = val,
                "Description:" => {
                    description = val;

                    packages.push(Package {
                        repo: _fmt_val(repo),
                        name: _fmt_val(name),
                        version: _fmt_val(version),
                        description: _fmt_val(description),
                    });
                    repo = "";
                    name = "";
                    version = "";
                    description = "";
                }
                _ => (),
            };
        }
    }
    packages
}

fn _fmt_val(value: &str) -> String {
    // "\"".to_string() + &value.trim().replace("\"", "'") + "\""
    value.trim().to_string()
}

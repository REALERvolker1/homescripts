use crate::{config, configlib, format, prompt};
use hostname;
use std::{env, fs};

#[derive(Debug, Clone, Copy)]
pub enum HostType {
    Local,
    Ssh,
    Distrobox,
    // TBD: Add more types
}
impl HostType {
    pub fn format(&self) -> format::Format {
        match self {
            HostType::Local => config::FMT_CONFIG.host,
            HostType::Ssh => config::FMT_CONFIG.ssh,
            HostType::Distrobox => config::FMT_CONFIG.distrobox,
        }
    }
}

/// Show if the user has a hostname, and what kind of host they are in.
#[derive(Debug, Clone)]
pub struct Hostname {
    // pub current: String,
    // pub format: configlib::Format,
    // pub host_type: HostType,
    pub segment: format::Segment,
}
impl Hostname {
    pub fn new() -> Option<Self> {
        // if it's in a distrobox, use the name of the distrobox instead of the hostname
        if let Ok(current) = env::var("CONTAINER_ID") {
            let host_type = HostType::Distrobox;
            let segment = format::Segment {
                text: Some(current),
            }
            Some(Self {
                current,
                format: host_type.format(),
                host_type,
            })
        } else {
            // Get the hostname
            let current = if let Ok(h) = hostname::get() {
                h.to_string_lossy().to_string()
            } else if let Ok(h) = env::var("HOST") {
                h
            } else if let Ok(h) = env::var("HOSTNAME") {
                h
            } else if let Ok(h) = fs::read_to_string("/etc/hostname") {
                String::from(h.trim())
            } else {
                // we've exhausted all options!
                String::new()
            };

            // Don't show the host if I'm on my main machine
            if &config::ENV_CONFIG.default_hostname == &current {
                return None;
            }

            let host_type = if configlib::env_exists("SSH_CONNECTION")
                || configlib::env_exists("SSH_CLIENT")
                || configlib::env_exists("SSH_TTY")
            {
                HostType::Ssh
            } else {
                HostType::Local
            };

            Some(Self {
                current,
                format: host_type.format(),
                host_type,
            })
        }
    }
}
impl prompt::ShellEnvModule for Hostname {
    fn const_get(&self) -> crate::format::Segment {
        crate::format::Segment::from(self.current.clone(), self.format)
    }
}

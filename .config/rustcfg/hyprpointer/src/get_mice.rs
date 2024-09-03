use hypesocket::hyprctl::{Hyprctl, HyprctlSocket};
use std::io::{self, StdoutLock, Write};

use crate::argparse::Args;

#[derive(Debug)]
pub struct MouseData {
    address: Vec<u8>,
    name: Vec<u8>,
    is_mouse: bool,
}
impl MouseData {
    pub fn try_parse(
        addr_line: &[u8],
        name_line: &[u8],
        mouse_names: &Vec<Vec<u8>>,
    ) -> Result<Self, MouseParseError> {
        let mut space_idx = None;
        let mut colon_idx = None;
        let mut i = addr_line.len() - 1;
        while i > 0 {
            if colon_idx == None && addr_line[i] == b':' {
                colon_idx = Some(i);
                if space_idx.is_some() {
                    return Err(MouseParseError::AddressLineOutOfOrder);
                }
            }

            if space_idx == None && addr_line[i] == b' ' {
                space_idx = Some(i);
                break;
            }
            i -= 1;
        }

        let colon_idx = colon_idx.ok_or(MouseParseError::MissingColonIdx)?;
        let space_idx = space_idx.ok_or(MouseParseError::MissingSpaceIdx)? + 1;

        let mut is_mouse = false;
        let mut mouse_name_pos = 0;

        for mouse_name in mouse_names {
            if is_mouse {
                break;
            }

            for name_char in name_line {
                if name_char.to_ascii_lowercase() == mouse_name[mouse_name_pos] {
                    mouse_name_pos += 1;

                    if mouse_name_pos == mouse_name.len() {
                        is_mouse = true;
                        break;
                    }
                }
            }
        }

        Ok(MouseData {
            address: addr_line[space_idx..colon_idx].to_vec(),
            name: name_line.to_vec(),
            is_mouse,
        })
    }
}
impl std::fmt::Display for MouseData {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{} - {} - {}",
            String::from_utf8_lossy(&self.address),
            String::from_utf8_lossy(&self.name),
            if self.is_mouse { "mouse" } else { "not mouse" }
        )
    }
}

#[inline]
pub fn query_data(
    ctlsock: &mut HyprctlSocket,
    stdout_lock: &mut StdoutLock<'_>,
    args: &Args,
) -> Result<bool, MouseDetectError> {
    let command = Hyprctl::new(None, &["devices"]);
    let output = ctlsock
        .run_hyprctl(&command)
        .map_err(|e| MouseDetectError::RunQuery(e))?;

    let mut lines = output.split(|n| *n == b'\n');

    let mut is_valid_state = false;

    while let Some(line) = lines.next() {
        if line == b"mice:" {
            is_valid_state = true;
            break;
        }
    }

    if !is_valid_state {
        return Err(MouseDetectError::GetMouseArray);
    }

    let mut mice_data = Vec::new();

    while let Some(addr_line) = lines.next() {
        let addr_line = addr_line.trim_ascii();
        if !addr_line.starts_with(b"Mouse") {
            continue;
        }

        let name_line = lines
            .next()
            .ok_or(MouseDetectError::MouseParse(MouseParseError::MissingName))?
            .trim_ascii();

        // let addr_line = lines
        //     .next()
        //     .ok_or(MouseDetectError::MouseParse(MouseParseError::MissingAddr))?
        //     .trim_ascii();
        // let name_line = lines
        //     .next()
        //     .ok_or(MouseDetectError::MouseParse(MouseParseError::MissingName))?
        //     .trim_ascii();

        match MouseData::try_parse(addr_line, name_line, &args.mouse_names) {
            Ok(d) => mice_data.push(d),
            Err(MouseParseError::MissingAddr) => break,
            Err(e) => return Err(e.into()),
        }

        // it ends with an empty line
        let Some(throwaway) = lines.next() else {
            break;
        };

        if throwaway.is_empty() {
            break;
        }
    }

    if mice_data.is_empty() {
        return Err(MouseDetectError::MissingDevices);
    }

    let mut has_mice = false;
    for data in mice_data {
        if data.is_mouse {
            has_mice = true;
            if args.is_silent {
                break;
            }

            // print regardless
            writeln!(stdout_lock, "{data}").map_err(|e| MouseDetectError::PrintError(e))?;
        } else if args.is_verbose {
            writeln!(stdout_lock, "{data}").map_err(|e| MouseDetectError::PrintError(e))?;
        }
    }

    Ok(has_mice)
}

#[derive(Debug, thiserror::Error)]
pub enum MouseParseError {
    #[error("Missing address")]
    MissingAddr,
    #[error("Missing name")]
    MissingName,
    #[error("Missing space in address line")]
    MissingSpaceIdx,
    #[error("Missing colon in address line")]
    MissingColonIdx,
    #[error("Invalid address line order")]
    AddressLineOutOfOrder,
}

#[derive(Debug, thiserror::Error)]
pub enum MouseDetectError {
    #[error("Failed to run device query with hyprctl: {0}")]
    RunQuery(io::Error),
    #[error("Failed to get available mice")]
    GetMouseArray,
    #[error("Failed to parse mouse data: {0}")]
    MouseParse(#[from] MouseParseError),
    #[error("No devices found")]
    MissingDevices,
    #[error("Error printing mouse data: {0}")]
    PrintError(io::Error),
}

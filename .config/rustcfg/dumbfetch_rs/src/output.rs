use rustix::rand;

use crate::entry::Entry;

pub fn print(entries: Vec<Entry>) {
    // let side_color = (unsafe { nix::libc::rand() }.unsigned_abs() % 256) as u8;
    // let mut rng = rand::rngs::SmallRng::seed_from_u64(match std::time::UNIX_EPOCH.elapsed() {
    //     Ok(d) => d.as_secs(),
    //     Err(_) => 0,
    // });
    // let side_color: u8 = rng.gen();
    let buffer = &mut [0u8; 1];
    let _ = rand::getrandom(buffer, rand::GetRandomFlags::INSECURE);
    let side_color = buffer[0];
    let box_side = format!("\x1b[0;38;5;{side_color}m│\x1b[0m");

    let entries = entries
        .into_iter()
        .map(|e| (e.length_please_keep_synced_with_display(), e))
        .collect::<Vec<_>>();

    let max_len = entries.iter().map(|e| e.0).max().unwrap_or(0);

    let horizontal = "─".repeat(max_len);

    let formatted = entries
        .into_iter()
        .map(|(len, e)| {
            let width = max_len - len;
            format!("{}{}{:width$}{}", &box_side, e, "", &box_side)
        })
        .collect::<Vec<_>>()
        .join("\n");

    println!["\x1b[0;38;5;{side_color}m╭{horizontal}╮\x1b[0m\n{formatted}\n\x1b[0;38;5;{side_color}m╰{horizontal}╯\x1b[0m"];
}

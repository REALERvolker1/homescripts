use arboard::{self, SetExtLinux};
use std::error;

fn main() -> Result<(), Box<dyn error::Error>> {
    // let cachefile = format!("{}/clip-monitor", env::var("XDG_RUNTIME_DIR").unwrap_or("/tmp".to_string()));
    // let cachefile_path = Path::new(&cachefile);
    clipboard_x()?;
    Ok(())
}
fn clipboard_x() -> Result<(), Box<dyn error::Error>> {
    let mut clipboard = arboard::Clipboard::new()?;
    loop {
        let text_res = clipboard.get_text();
        let img_res = clipboard.get_image();
        let set = clipboard.set();
        if text_res.is_ok() {
            let text = text_res.unwrap();
            println!("text\n{}", text);
            set.wait().text(text)?;
        } else if img_res.is_ok() {
            let img = img_res.unwrap();
            println!("img");
            set.wait().image(img)?;
        } else {
            println!("clipboard empty");
            set.wait().text("")?;
        }
    }
    //Ok(())
}

// async fn clipboard_w() -> Result<(), Box<dyn error::Error>> {
//     let mut main_command = Command::new("wl-paste");
//     main_command.args(["-w", "echo", "now"]);
//     main_command.stdout(Stdio::piped());

//     let mut command = main_command.spawn()?;
//     let stdout = command.stdout.take().unwrap();

//     let mut reader = BufReader::new(stdout).lines();

//     tokio::spawn(async move {
//         let status = command.wait().await.expect("Child process exit status could not be acquired");

//         println!("child status was: {}", status);
//     });
//     let clipboard = wl_clipboard_rs::paste::get_contents(
//         wl_clipboard_rs::paste::ClipboardType::Regular,
//         wl_clipboard_rs::paste::Seat::Unspecified,
//         wl_clipboard_rs::paste::MimeType::Any
//     );
//     while let Some(line) = reader.next_line().await? {
//         println!("Line: {}", line);
//     }

//     // let mut command = process::Command::new("wl-paste")
//     //     .args(["-w", "echo", "now"])
//     //     .stdout(process::Stdio::piped())
//     //     .spawn()?;

//     // let stdout = command.stdout.take();
//     // let reader_thread = thread::spawn(move || {
//     //     let reader = BufReader::new(stdout);
//     //     for line in reader.lines() {
//     //         if let Ok(line) = line {
//     //             // Process each line here
//     //             println!("Received line: {}", line);
//     //             // You can call your function here with 'line' as an argument
//     //         }
//     //     }
//     // });

//     Ok(())
// }

// fn clipboard_x() -> Result<(), Box<dyn error::Error>> {
//     let clipboard = x11_clipboard::Clipboard::new()?;
//     loop {
//         let clipboard_content = clipboard.load_wait(
//             clipboard.setter.atoms.clipboard,
//             clipboard.setter.atoms.string,
//             clipboard.setter.atoms.property
//         )?;
//         // let primary_content = clipboard.load_wait(
//         //     clipboard.setter.atoms.primary,
//         //     clipboard.setter.atoms.string,
//         //     clipboard.setter.atoms.property
//         // )?;
//         // let content = clipboard.load(
//         //     clipboard.setter.atoms.clipboard,
//         //     clipboard.setter.atoms.utf8_string,
//         //     clipboard.setter.atoms.property,
//         //     Duration::from_secs(3)
//         // )?;
//         unsafe {
// println!("{}", String::from_utf8_unchecked(clipboard_content));
//         }

//         // println!("primary:\n\n{}", String::from_utf8(primary_content).unwrap());
//     }
//     Ok(())
// }

// fn clipboard_w() -> Result<(), Box<dyn error::Error>> {
//     println!("Wayland clipboard");
//     Ok(())
// }

use crate::*;
use gtk4::prelude::*;
// huge shoutout to https://github.com/JakeStanger/ironbar/blob/master/src/bar.rs

pub struct Bar {
    pub name: String,
    pub monitor_name: String,
}

// pub async fn gtk_main() -> ModResult<()> {
//     let app = gtk4::Application::builder().application_id(APP_ID).build();

//     glib_exit_code_to_mod_result(app.run())
// }

// pub fn gtk_ui() {

// }

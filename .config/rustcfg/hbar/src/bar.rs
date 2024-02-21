use crate::prelude::*;
use gtk4::{prelude::*, Application, ApplicationWindow, Button, CenterBox, Label};
use std::cell::Cell;

// huge shoutout to https://github.com/JakeStanger/ironbar/blob/master/src/bar.rs
// also https://gtk-rs.org/gtk4-rs/stable/latest/book/hello_world.html

pub struct Bar {
    pub name: String,
    pub monitor_name: String,
    application: gtk4::Application,
}
impl Bar {
    pub fn run() -> color_eyre::Result<()> {
        let app = gtk4::Application::builder().application_id(APP_ID).build();

        app.connect_activate(build_ui);

        let run = app.run_with_args::<&str>(&[]);
        warn!("GTK application exited with code {:?}", run);
        glib_exit_code_to_mod_result(run)?;

        // gio::DBusInterface::
        Ok(())
    }
    pub fn insert_widget(&self) -> ModResult<()> {
        todo!()
    }
}

fn build_ui(app: &Application) {
    let window = ApplicationWindow::builder()
        .application(app)
        .title(APP_ID)
        .build();

    let main_container = CenterBox::builder()
        .orientation(gtk4::Orientation::Horizontal)
        .build();

    let num: Rc<Cell<u8>> = Rc::new(Cell::new(0));

    let state_label = Label::builder().label("Current count is 0").build();
    main_container.set_center_widget(Some(&state_label));

    let inc_button = Button::builder().label("Increment").build();
    inc_button.connect_clicked(glib::clone!(@strong num, @weak state_label => move |_|{
        let result = num.get().wrapping_add(1);
        num.set(result);
        let label = format!("Added. Current count is {}", result);
        state_label.set_label(&label);
    }));
    main_container.set_start_widget(Some(&inc_button));

    let dec_button = Button::builder().label("Decrement").build();
    dec_button.connect_clicked(glib::clone!(@strong num, @weak state_label => move |_|{
        let result = num.get().wrapping_sub(1);
        num.set(result);
        let label = format!("Subtracted. Current count is {}", result);
        state_label.set_label(&label);
    }));
    dec_button.connect_has_tooltip_notify(glib::clone!(@strong num => move |b| {
        let label = format!("Subtract 1 from {}?", num.get());
        b.set_label(&label);
    }));

    main_container.set_end_widget(Some(&dec_button));

    window.set_child(Some(&main_container));

    window.present();
}

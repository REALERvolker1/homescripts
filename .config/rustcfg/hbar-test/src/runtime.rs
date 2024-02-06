use crate::*;

/// TODO: MAke async
pub async fn run() -> NoBruh {
    let app = Application::builder().application_id(APP_ID).build();

    app.connect_activate(|app| {
        let window = window_init(app);
        window.present();
    });

    let err = app.run();
    if err.value() != 0 {
        Err(err.into())
    } else {
        Ok(())
    }
}

fn window_init(app: &Application) -> ApplicationWindow {
    let win = ApplicationWindow::builder()
        .application(app)
        .title("Bruh")
        .default_width(400)
        .default_height(300)
        .build();

    let button = Button::with_label("Workspace");
    button.connect_clicked(|_| {
        println!("Workspace button clicked");
    });
    win.set_child(Some(&button));

    win
}

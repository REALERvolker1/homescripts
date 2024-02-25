use gtk4::prelude::*;

/// This is my minimal reproduction of a gtk application that receives signals from some sort of
/// backend, and changes its state in response.
///
/// Lots of credit to https://github.com/oknozor/stray/blob/main/gtk-tray/src/main.rs, they wrote their
/// own version, and without it I would still be struggling trying to get this to work.
///
/// This kind of thing is not well documented, although I think it should have definitely been in the gtk4 book at least.
async fn example() {
    let application = gtk4::Application::builder()
        .application_id("com.github.REALERvolker1.example")
        .build();

    application.connect_activate(|app| {
        let inner_text = gtk4::Label::builder().label("Hello World").build();

        let window = gtk4::ApplicationWindow::builder()
            .title(env!("CARGO_PKG_NAME"))
            .application(app)
            .child(&inner_text)
            .build();

        // initialize mpsc here so that the receiver is not moved too fast
        let (sender, mut receiver) = tokio::sync::mpsc::channel::<String>(32);

        let signal_receiver = async move {
            while let Some(maybe_text) = receiver.recv().await {
                inner_text.set_text(&maybe_text);
            }
        };

        tokio::spawn(async move {
            eprintln!("Started sender task");
            let mut count = 0;
            loop {
                count += 1;
                let send_text = format!("Loop ran {count} times");

                // I join these here so they wait in parallel
                let (send, _) = tokio::join!(
                    sender.send(send_text),
                    tokio::time::sleep(std::time::Duration::from_secs(1))
                );

                // panic on failure
                send.unwrap();
            }
        });

        let main_context = gtk4::glib::MainContext::default();
        main_context.spawn_local(signal_receiver);

        window.present();
    });

    eprintln!("Starting up...");
    // use run_with_args so that gtk doesn't try to parse args and fail spectacularly
    let exit_code = application.run_with_args::<&str>(&[]);
    std::process::exit(exit_code.value());
}

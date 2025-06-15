mod env;
mod io_methods;
mod langs;
mod templates;
mod tui;

fn main() {
    unsafe {
        crate::io_methods::signal_runtime_init().expect("Failed to register signal handlers");
    }

    std::process::exit(crate::io_methods::block_join_sigloop());
}

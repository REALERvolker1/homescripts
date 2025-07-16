mod env;
mod io_methods;
mod langs;
mod templates;
mod tui;

fn main() -> () {
    std::thread::spawn(move || {
        let mut term = io_methods::TermHandle::new();
        io_methods::SigThread::sigloop(&mut term)
    });

    loop {}
}

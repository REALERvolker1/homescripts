mod gtk_responsive_futures_lite;
mod gtk_responsive_tokio;

fn main() {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async { gtk_responsive_tokio::example() });
}

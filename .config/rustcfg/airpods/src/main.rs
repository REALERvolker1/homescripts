#[tokio::main(flavor = "current_thread")]
async fn main() {
    let conn = dbus::nonblock::Connection::
    let pods = airinfo::find_pods().await.expect("Could not find airpods!");

    println!("{:#?}", pods);
}

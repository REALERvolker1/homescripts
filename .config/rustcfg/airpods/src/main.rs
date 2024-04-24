fn main() -> Result<(), dbus::Error> {
    let (resource, conn) = dbus_tokio::connection::new_system_local()?;

    let async_main = async {
        let pods = airinfo::find_pods().await.expect("Could not find airpods!");
        println!("{:#?}", pods);

        Ok::<(), dbus::Error>(())
    };

    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_time()
        .enable_io()
        .build()
        .expect("Could not build the tokio runtime!");

    runtime.block_on(async_main)?;

    Ok(())
}

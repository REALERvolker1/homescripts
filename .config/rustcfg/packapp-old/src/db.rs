use std::{
    env,
    error::Error,
    path::{Path, PathBuf},
};

use crate::config::Config;

use sqlx::{self, sqlite::SqliteConnectOptions, Connection, Sqlite, SqliteConnection, SqlitePool};

// impl AsRef<Path>
pub async fn init(config: Config) -> Result<(), sqlx::Error> {
    let options = SqliteConnectOptions::new()
        .filename(config.dbfile)
        .create_if_missing(true);

    let pool = SqlitePool::connect_with(options).await?;

    if let Ok(initial_query) = sqlx::query("select count(*) from (select 0 from packages limit 1);")
        .execute(&pool)
        .await
    {
        println!("success, {:?}", &initial_query);
    } else {
        println!("Creating package cache...");
    }

    Ok(())
}

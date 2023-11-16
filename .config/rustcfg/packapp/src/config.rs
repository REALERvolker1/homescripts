use sqlx::{self, sqlite::SqliteConnectOptions, SqlitePool};
use std::{
    env,
    path::{Path, PathBuf},
};

use crate::backends::Backend;

#[derive(Debug, Clone)]
pub struct Config {
    pub dbfile: PathBuf,
    pub backend: Backend,
    pub db_pool: SqlitePool,
}
impl Config {
    pub async fn new_with_backend(backend: Backend) -> Result<Self, sqlx::Error> {
        let config_basepath = format!(
            "{}/packapp.db",
            env::var("XDG_RUNTIME_DIR").unwrap_or(String::from("/tmp"))
        );
        let configpath = Path::new(&config_basepath);

        let options = SqliteConnectOptions::new()
            .filename(&config_basepath)
            .create_if_missing(true);

        let pool = SqlitePool::connect_with(options).await?;

        if let Ok(initial_query) =
            sqlx::query("select count(*) from (select 0 from packages limit 1);")
                .execute(&pool)
                .await
        {
            println!("success, {:?}", &initial_query);
        } else {
            println!("Creating package cache...");
        }

        Ok(Self {
            dbfile: configpath.to_path_buf(),
            backend: backend,
            db_pool: pool,
        })
    }
    pub async fn new() -> Result<Self, sqlx::Error> {
        if let Some(backend) = Backend::new().await {
            let config = Config::new_with_backend(backend).await?;
            Ok(config)
        } else {
            panic!("Could not get an available backend!")
        }
    }
}

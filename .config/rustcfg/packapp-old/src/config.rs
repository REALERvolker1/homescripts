use futures::{future, StreamExt, TryStreamExt};
use sqlx::{self, sqlite::SqliteConnectOptions, Row, SqlitePool};
use std::{
    env,
    path::{Path, PathBuf},
};

use crate::backends::{self, Package};

#[derive(Debug, Clone)]
pub struct Config {
    pub dbfile: PathBuf,
    pub backend: backends::Backend,
    pub db_pool: SqlitePool,
}
impl Config {
    pub async fn new(
        backend_or_none: Option<backends::AvailableBackend>,
    ) -> Result<Self, sqlx::Error> {
        let config_basepath = format!(
            "{}/packapp.db",
            env::var("XDG_RUNTIME_DIR").unwrap_or(String::from("/tmp"))
        );
        let configpath = Path::new(&config_basepath);
        println!("{}", &config_basepath);
        let db_exists = configpath.exists();

        let options = SqliteConnectOptions::new()
            .filename(&config_basepath)
            .create_if_missing(true);

        let pool = SqlitePool::connect_with(options).await?;

        // let backend = create_cache(backend_or_none, &pool).await?;

        if db_exists {
            let current_backend =
                sqlx::query_as::<_, Package>("SELECT * FROM metadata;").fetch(&pool);

            let mut all_packages = Vec::new();
            let mut inst_packages = Vec::new();

            for (table, packages) in [
                ("all_packages", all_packages),
                ("inst_packages", inst_packages),
            ] {
                let mut rows = sqlx::query_as::<_, Package>(&format!("SELECT * FROM '{}';", table))
                    .fetch(&pool);

                while let Some(row) = rows.try_next().await? {
                    packages.push(row)
                }
            }

            // let mut rows =
            //     sqlx::query_as::<_, Package>("select * from 'all_packages';").fetch(&pool);

            // while let Some(row) = rows.try_next().await? {
            // }
            // backend = create_cache(backend_or_none, &pool).await?;
        } else {
            backend = create_cache(backend_or_none, &pool).await?;
            // panic!("nocache");
            // println!("{:#?}", backend.installed);
        }

        panic!("done");
        // if let Ok(initial_query) =
        //     sqlx::query("select count(*) from (select 0 from 'packages' limit 1);")
        //         .execute(&pool)
        //         .await
        // {
        //     // if let Ok(populate_backend) = sqlx::query("select * from 'packages';")
        //     //     // .bind(raw_package_data)
        //     //     // .fetch(&pool)
        //     //     .execute(&pool)
        //     //     .await
        //     // {
        //     //     println!("success, {:?}", &populate_backend);
        //     //     panic!("lmao hi");
        //     //     backend = create_cache(backend_or_none, &pool).await?;
        //     // } else {
        //     //     backend = create_cache(backend_or_none, &pool).await?;
        //     // }

        // } else {
        //     // panic!("nocache");

        // };
        Ok(Self {
            dbfile: configpath.to_path_buf(),
            backend: backend,
            db_pool: pool,
        })
    }
    // pub async fn new() -> Result<Self, sqlx::Error> {
    //     if let Some(backend) = Backend::new().await {
    //         let config = Config::new_with_backend(backend).await?;
    //         Ok(config)
    //     } else {
    //         panic!("Could not get an available backend!")
    //     }
    // }
}

async fn create_cache(
    backendopt: Option<backends::AvailableBackend>,
    pool: &SqlitePool,
) -> Result<backends::Backend, sqlx::Error> {
    println!("Creating package cache...");
    let backend = backends::Backend::new(backendopt).await?;

    sqlx::query("CREATE TABLE metadata (type TEXT);")
        .execute(pool)
        .await?;
    sqlx::query(&format!(
        "INSERT INTO metadata VALUES ('{:?}')",
        backend.backend_type
    ))
    .execute(pool)
    .await?;

    println!("INSERT INTO metadata VALUES ('{:?}')", backend.backend_type);

    for (table, packages) in [
        ("all_packages", &backend.packages),
        ("inst_packages", &backend.installed),
    ] {
        sqlx::query(&format!(
            "CREATE TABLE {} (repo TEXT, name TEXT, version TEXT, description TEXT);",
            table
        ))
        .execute(pool)
        .await?;
        let query_strings = packages
            .iter()
            .map(|i| {
                format!(
                    "INSERT INTO 'packages' VALUES ('{}','{}','{}','{}');",
                    &i.repo.replace("'", "’"),
                    &i.name.replace("'", "’"),
                    &i.version.replace("'", "’"),
                    &i.description.replace("'", "’")
                )
            })
            .collect::<Vec<String>>();

        // let queries = query_strings.iter().map(|i| sqlx::query(i).execute(pool));

        let mut queryjoin = futures::stream::FuturesOrdered::new();
        for i in query_strings.iter() {
            queryjoin.push_back(sqlx::query(i).execute(pool))
        }

        // future::join_all(queries);
    }

    // let pool = borrow_pool

    //  (repo, name, version, description)
    // let cache_pkgs = backend
    //     .clone()
    //     .packages
    //     .iter()
    //     .map(|i| {
    //         format!(
    //             "INSERT INTO 'packages' VALUES ('{}','{}','{}','{}');",
    //             &i.repo.replace("'", "’"),
    //             &i.name.replace("'", "’"),
    //             &i.version.replace("'", "’"),
    //             &i.description.replace("'", "’")
    //         )
    //     })
    //     .collect::<Vec<String>>();
    // let queries = future::join_all(

    // )
    // .await;
    // for i in all_pkgs {
    //     println!("{}", &i);
    //     let query = sqlx::query(&i).execute(pool).await?;
    // }

    // let errors = queries.iter().filter_map(|i| i.as_ref().err());
    // for err in errors {
    //     println!("{:?}", err);
    // }

    // let cache_pkgs = backend
    //     .clone()
    //     .packages
    //     .iter()
    //     .map(|i| {
    //         format!(
    //             "insert into 'packages' ({},{},{},{});",
    //             &i.repo, &i.name, &i.version, &i.description
    //         )
    //     })
    //     .collect::<Vec<String>>();

    // let insert_query_string = cache_pkgs.join("\n");
    // sqlx::query(&insert_query_string).execute(pool).await?;
    Ok(backend)
}

fn _querymap(backend: &Vec<backends::Package>) -> Vec<String> {
    backend
        .iter()
        .map(|i| {
            format!(
                "INSERT INTO 'packages' VALUES ('{}','{}','{}','{}');",
                &i.repo.replace("'", "’"),
                &i.name.replace("'", "’"),
                &i.version.replace("'", "’"),
                &i.description.replace("'", "’")
            )
        })
        .collect::<Vec<String>>()
}

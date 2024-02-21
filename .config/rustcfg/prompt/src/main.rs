#![feature(
    const_option,
    const_trait_impl,
    effects,
    const_for,
    portable_simd,
    trait_alias
)]

pub mod cli;
pub mod config;
pub mod error;
pub mod modules;
pub mod prelude;
pub mod render;

use prelude::*;

fn main() -> R<()> {
    let current_operation = cli::parse_arg(env::args().skip(1).next());
    println!("Hello, world! Op is {}", current_operation);

    config::PrecmdConfig::default().export_self()?;

    Ok(())
}

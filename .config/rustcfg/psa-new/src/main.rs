use psa_new::*;

fn main() -> simple_eyre::Result<()> {
    simple_eyre::install().unwrap();

    let god_object = GodObject::new().wrap_err("Failed to create runtime cache!")?;
    let test_prog = god_object.process_cache.get_random();

    let blah = test_prog
        .args()
        .iter()
        .map(|a| formatting::format_argument(a))
        .collect_vec()
        .join(" ");

    let proc_tree = formatting::proc_tree(test_prog.pid(), &god_object.process_cache);

    println!("{blah}");
    println!("{proc_tree}");
    Ok(())
}

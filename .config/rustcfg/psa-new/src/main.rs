use psa_new::*;

fn main() -> simple_eyre::Result<()> {
    simple_eyre::install().unwrap();

    let god_object = GodObject::new().wrap_err("Failed to create runtime cache!")?;
    let test_prog = god_object.process_cache.get_random();

    let my_user = users::TrackedUser::from_uid(1000.into()).unwrap();
    let root_user = users::TrackedUser::from_uid(0.into()).unwrap();
    let dbus_user = users::TrackedUser::from_uid(81.into()).unwrap();

    // runs just fine
    assert_eq!(my_user.user_type, users::UserType::Myself);

    // assertion `left == right` failed
    //   left: Myself
    //   right: Root
    assert_eq!(root_user.user_type, users::UserType::Root);

    // assertion `left == right` failed
    //   left: Myself
    //   right: Other
    assert_eq!(dbus_user.user_type, users::UserType::Other);

    // let blah = test_prog
    //     .args()
    //     .iter()
    //     .map(|a| formatting::format_argument(a))
    //     .collect_vec()
    //     .join(" ");

    let proc_tree = formatting::proc_tree(test_prog.pid(), &god_object.process_cache);

    println!(
        "{}",
        formatting::format_uid(test_prog.uid(), test_prog.euid(), &god_object.user_cache)
    );

    // println!("{blah}");
    println!("{proc_tree}");
    Ok(())
}

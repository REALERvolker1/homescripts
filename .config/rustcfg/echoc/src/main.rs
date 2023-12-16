use std::{
    env::args,
    io::{prelude::*, stdout},
};

fn main() {
    // if there are no args, print a blank line
    let first_opt = if let Some(first_opt) = args().nth(1) {
        first_opt
    } else {
        println!("");
        return;
    };

    let env_args = args();

    let (print_args_iter, expand_escapes, print_newline) = match first_opt.as_str() {
        "-e" => (env_args.skip(2), true, true),
        "-n" => (env_args.skip(2), false, false),
        "-ne" | "-en" => (env_args.skip(2), true, false),
        "--" => (env_args.skip(2), false, true),
        _ => (env_args.skip(1), false, true),
    };

    let print_args = if expand_escapes {
        print_args_iter
            .map(|i| {
                i.replace("\\n", "\n")
                    .replace("\\t", "\t")
                    .replace("\\0", "\0")
                    .replace("\\e", "\x1b")
                    .replace("\\x1b", "\x1b")
                    .replace("\\033", "\x1b")
            })
            .collect::<Vec<String>>()
    } else {
        print_args_iter.collect::<Vec<String>>()
    }
    .join(" ");

    let mut stdoutlock = stdout().lock();

    if print_newline {
        stdoutlock.write_all(print_args.as_bytes()).unwrap_or(());
        stdoutlock.write_all(b"\n").unwrap_or(());
    } else {
        stdoutlock.write_all(print_args.as_bytes()).unwrap_or(());
    }
}

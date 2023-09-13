use std::{
    io,
    error,
    process,
    env,
};
use serde_json;

pub mod config;
// mod options;
mod init;

#[derive(Debug, PartialEq, Clone)]
struct ArgOptions {
    shell: String,
    init: bool
}
fn build_arg_options() -> Result<ArgOptions, io::Error> {
    let mut arg_shell = String::new();
    let mut arg_init = false;
    for arg in env::args().skip(1) {
        if let Some(position) = arg.find("=") {
            let (key, val) = arg.split_at(position + 1);
            match key {
                "--shell=" => arg_shell = val.to_string(),
                _ => continue,
            }
        }
        else {
            match arg.as_str() {
                "--init" => arg_init = true,
                _ => continue
            }
        }
    }
    Ok(ArgOptions {
        shell: arg_shell,
        init: arg_init
    })
}

fn main() -> Result<(), Box<dyn error::Error>> {
    let arg_options = build_arg_options()?;
    let conf = config::generate_config(&arg_options.shell)?;

    // let opts = options::get_opts()?;
    let res_opts = config::get_opts();
    if res_opts.is_err() || arg_options.init {
        init(&conf.shell)?;
        process::exit(0)
    }

    let opts = res_opts.unwrap();
    // println!("{:#?}", opts);
    // println!("{:#?}", conf);
    print_prompt(conf, opts)?;
    Ok(())
}

fn init(current_shell: &config::Shell) -> Result<(), Box<dyn error::Error>> {
    println!("\n#VLKPROMPT INIT SCRIPT\n");
    println!("{}", init::INIT_PRECMD_SCRIPT_ZSH);
    Ok(())
}

// macro_rules! section_fmt {
//     ($b:tt,$t:expr,$o:expr,$cfg:expr,$opt:expr) => {
//         {
//             let cfg = config.clone();
//             let opt = options.clone();
//             println!("{}{}{} {} {} {}",
//                 $cfg.colors.sgr,
//                 $cfg.colors.background.$b,
//                 $cfg.colors.$t,
//                 $cfg.icons.$b,
//                 $opt.$o,
//                 $cfg.colors.sgr
//             );
//         }
//     };
// }

fn print_prompt(config: config::Config, options: config::Options) -> Result<(), Box<dyn error::Error>> {
    // dir color
    let mut prompt: Vec<String> = Vec::new();
    // {
    //     let cfg = config.clone();
    //     let opt = options.clone();
    //     println!("{}{}{} {} {} {}",
    //         cfg.colors.sgr,
    //         cfg.colors.background.err,
    //         cfg.colors.text_light,
    //         cfg.icons.err,
    //         opt.error,
    //         cfg.colors.sgr,
    //     );
    // }
    let defined_config = config::define_config(config.clone(), options.clone())?;
    if options.has_err {
        prompt.push(defined_config.err);
        if &options.has_jobs == &true {
            prompt.push(defined_config.err_job)
        }
        else {
            prompt.push(defined_config.err_dir)
        }
    }
    if options.has_jobs {
        prompt.push(defined_config.job)
    }
    prompt.push(defined_config.dir);
    if options.has_sudo {
        prompt.push(defined_config.dir_sud)
    }
    else {
        prompt.push(defined_config.dir_end)
    }
    println!("{} hello", prompt.join(""));

    Ok(())
}

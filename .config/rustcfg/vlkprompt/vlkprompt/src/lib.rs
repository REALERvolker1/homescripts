use std::{env, io};
use zsh_module::{Builtin, MaybeError, Module, ModuleBuilder, Opts};

mod constants;
mod precmd;
mod sh;

zsh_module::export_module!(vlkprompt, setup);

#[derive(Debug, Clone)]
struct PromptState {
    name: String,
}
impl Default for PromptState {
    fn default() -> Self {
        Self {
            name: "".to_owned(),
        }
    }
}
impl PromptState {
    pub fn greet_cmd(&mut self, _name: &str, args: &[&str], _opts: Opts) -> MaybeError {
        if !args.is_empty() {
            self.name = args
                .iter()
                .map(|a| a.to_owned())
                .collect::<Vec<_>>()
                .join(" ");
            println!("Setting name to {}", self.name);
        }
        println!("Hello, {}!", self.name);
        Ok(())
    }
    pub fn precmd(&mut self, _name: &str, _args: &[&str], _opts: Opts) -> MaybeError {
        // let cwd = env::current_dir()?;
        // // #[cfg(feature = "git2")]
        // if let Some(repo) = precmd::cwd::repo_string(cwd.as_path()) {
        //     println!("{}", repo);
        // }
        if precmd::sudo::has_sudo() {
            println!("Sudo cached");
        }
        Ok(())
    }
}

fn setup() -> Result<Module, Box<dyn std::error::Error>> {
    let module = ModuleBuilder::new(PromptState::default())
        .builtin(PromptState::precmd, Builtin::new("libvlkprompt::precmd"))
        .builtin(PromptState::greet_cmd, Builtin::new("libvlkprompt::greet"))
        .build();
    Ok(module)
}
pub impl Stateful {
    /// update the current state
    pub fn update(&mut self) -> ();
    fn get_init_value(&mut self) -> ();
}

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn it_works() {
//         let result = add(2, 2);
//         assert_eq!(result, 4);
//     }
// }

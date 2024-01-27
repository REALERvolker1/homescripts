use crate::{types::*, *};
use zsh_module::{zsh, Opts};

pub type Bruh = Result<(), Box<dyn std::error::Error>>;

#[derive(Debug, Default)]
pub struct Module {
    counter: u32,
    is_initialized: bool,
}
impl Module {
    /// Create a new module.
    ///
    /// TODO: Add helpful error type
    pub fn new_zsh_module() -> Result<zsh_module::Module, Box<dyn std::error::Error>> {
        let me = Self::default();

        // TODO: Iterate over this struct's methods, only the methods that are zsh commands, preferably with some sort of decorator that also adds documentation.
        // TODO: Find a crate or library to do aforemetioned TODO stuff for me
        let module = zsh_module::ModuleBuilder::new(me)
            .builtin(Self::count, zsh_module::Builtin::new("count"))
            .builtin(Self::get_count, zsh_module::Builtin::new("get_count"))
            .builtin(
                Self::get_zsh_version,
                zsh_module::Builtin::new("get_zsh_version"),
            )
            .build();

        Ok(module)
    }

    /// A method to get the zsh_version
    fn get_zsh_version(&mut self, name: &str, args: &[&str], _opts: Opts) -> Bruh {
        #[cfg(debug_assertions)]
        eprintln!("name: {}, args: [{}]", name, args.join(", "));

        if let Ok(version) = std::env::var("ZSH_VERSION") {
            println!("{}", version);
        } else {
            eprintln!("Failed to get ZSH_VERSION -- likely not exported");
        }

        Ok(())
    }

    /// A method for counting up
    fn count(&mut self, name: &str, args: &[&str], _opts: Opts) -> Bruh {
        #[cfg(debug_assertions)]
        eprintln!("name: {}, args: [{}]", name, args.join(", "));

        if !self.is_initialized {
            self.is_initialized = true;
        }
        self.counter += 1;
        // TODO: Add environment variable reflecting the current count, without using zsh::eval_simple
        let eval_string = format!("typeset -i __counter_count={}", self.counter);
        zsh::eval_simple(&eval_string)?;
        Ok(())
    }

    /// A method for getting the current count
    ///
    /// TODO: Add environment variable reflecting the current count
    fn get_count(&mut self, name: &str, args: &[&str], _opts: Opts) -> Bruh {
        #[cfg(debug_assertions)]
        eprintln!("name: {}, args: [{}]", name, args.join(", "));

        if !self.is_initialized {
            // TODO: See if $__counter_count is set, and give a different error message if so
            eprintln!("Module not initialized yet!");
            return Err("Module not initialized yet!".into());
        }

        println!("{}", self.counter);
        Ok(())
    }
}

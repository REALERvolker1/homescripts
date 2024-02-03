use zsh_module::{Builtin, MaybeZError, Module, ModuleBuilder, Opts, ZError};

zsh_module::export_module!(commit_test, setup);

#[derive(Debug, Default)]
struct State {
    count: usize,
}
impl State {
    pub fn add_count(&mut self, _name: &str, _args: &[&str], _opts: Opts) -> MaybeZError {
        self.count += 1;
        println!("{}", self.count);
        Ok(())
    }
    pub fn subtract_count(&mut self, _name: &str, _args: &[&str], _opts: Opts) -> MaybeZError {
        self.count -= 1;
        println!("{}", self.count);
        Ok(())
    }
}

fn setup() -> Result<Module, ZError> {
    let module = ModuleBuilder::new(State::default())
        .builtin(State::add_count, Builtin::new("add_count"))
        .builtin(State::subtract_count, Builtin::new("subtract_count"))
        .build();
    Ok(module)
}

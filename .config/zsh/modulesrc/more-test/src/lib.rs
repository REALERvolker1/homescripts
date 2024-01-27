pub mod module;
pub mod types;

zsh_module::export_module!(more_test, setup);

/// Initializes the module in the zsh environment upon being zmodloaded
fn setup() -> Result<zsh_module::Module, Box<dyn std::error::Error>> {
    let module = module::Module::new_zsh_module()?;
    Ok(module)
}
// zsh-workers@zsh.org
/*
how zsh handles it's variables
how it's variables are exported (setenv?)
If the keys and values are copied or expected to be leaked/alloccd with malloc by the caller
*/

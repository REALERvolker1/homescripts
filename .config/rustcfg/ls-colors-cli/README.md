# ls-colors-cli

---

# WIP DOCUMENTATION!!! EXPECT IT TO BE ENTIRELY WRONG!!!!!

I am learning rust, and I decided to make a better CLI for the lscolors crate, since its current one is... lackluster.

It optionally includes a zsh module, for a faster CLI experience. to use it, simply run the following commands:

```bash
git clone https://github.com/REALERvolker1/ls-colors-cli
cd ls-colors-cli
cargo build --release

# the directory can be whatever you like, usually it's something like "moduledir/author/module.so"
cp ./target/release/ls-colors.so ~/.zsh/modules/REALERvolker1/
# in your .zshrc
module_path+=("$ZDOTDIR/modules")
```

This crate was heavily inspired by [sharkdp/lscolors](https://github.com/sharkdp/lscolors)

Useful documentation:

-   https://www.maizure.org/projects/decoded-gnu-coreutils/ls.html
-   https://github.com/coreutils/coreutils/blob/master/src/dircolors.c

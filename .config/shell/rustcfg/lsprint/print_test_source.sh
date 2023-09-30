# shellcheck shell=bash
lsprint_test() {
    oldpwd="$PWD"
    cd ~/.config/shell/rustcfg/lsprint &>/dev/null || return 69
    cargo build
    cd "$oldpwd" &>/dev/null || return 96
    ~/.config/shell/rustcfg/lsprint/target/debug/lsprint
}
echo "run command 'lsprint_test' to test lsprint"

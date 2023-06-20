#!/usr/bin/zsh
# a script by vlk to recompile my zsh shit

set -euo pipefail

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
ZPLUGIN_DIR="${ZPLUGIN_DIR:-$HOME/.zsh-plugins}"

atuin_gen="$ZPLUGIN_DIR/atuin.zsh"

SEDSTR="s|^|[✅] |
s|${ZDOTDIR}|[94m~[92mzsh[0m|
s|${ZPLUGIN_DIR}|[32m\$ZPLUGIN_DIR[0m|
s|$HOME/bin|[94m~[32mbin[0m|
s|$HOME|[94m~[0m|
s|site-functions|s..fn|"

remove_compiled() {
    local i
    find "$ZDOTDIR/" -type f -name '*.zwc' | while read -r i; do
        rm "$i" || echo "Failed to remove '$i'"
    done
}

generate_atuin() {
    if command -v atuin &>/dev/null; then
        printf '%s\n' \
            'if [[ "$TERM" != linux ]]; then' \
            "$(atuin init zsh | sed 's/echoti/#echoti/g')" \
            'fi' |
            sed 's/^[[:space:]]*#/#/g' | grep -v -e '^#' -e '^$' >"$atuin_gen"
    else
        echo "Error, command 'atuin' is not installed!" >&2
        return 1
    fi
}

update_plugins() {
    ping -c 1 'www.github.com' >/dev/null || return 1 # check for internet
    local i
    local gp
    for i in "$ZPLUGIN_DIR/"*(/); do
        cd "$i"
        gp="$(git pull)"
        case "$gp" in
        'Already up to date.'*)
            echo '[☁️]' "${i##*/}"
            ;;
        *)
            echo "$gp"
            ;;
        esac
    done
}

install_plugins() {
    if [ -z "${ZSH_PLUGINS:-}" ]; then
        printf '%b\n' "Error, please set your ZSH_PLUGINS environment variable with NEWLINE splits!" \
            '\e[35mexport \e[1;36mZSH_PLUGINS\e[0m=\e[32m"https://example.com/plugin1.git' 'https://example.com/plugin2.git"\e[0m'
        exit 1
    fi
    [ ! -d "$ZPLUGIN_DIR" ] && mkdir -p "$ZPLUGIN_DIR"
    cd "$ZPLUGIN_DIR"
    local i
    echo "$ZSH_PLUGINS" | while read -r i; do
        echo "plugin $i"
        git clone "$i" || continue
    done
}

compile_everything() {
    for i in \
        "$ZDOTDIR/.zshrc" \
        "$ZDOTDIR/.zprofile" \
        "$atuin_gen" \
        "$ZDOTDIR/rc.d/"*".zsh"; do
        zcompile "$i" && echo "$i" | sed "$SEDSTR"
    done
}

action="${1:-}"
case "${action:-}" in
'--uncompile')
    remove_compiled
    ;;
'--update')
    update_plugins
    ;;
'--install-plugins')
    install_plugins
    generate_atuin
    ;;
'--recompile')
    remove_compiled
    generate_atuin
    update_plugins
    compile_everything
    ;;
*)
    printf '%s\t%s\n' \
        '--uncompile      ' 'remove compiled zwcs' \
        '--update         ' 'update plugins' \
        '--install-plugins' 'install all your plugins (specified by the newline-separated $ZSH_PLUGINS environment variable)' \
        '--recompile      ' 'update your plugins and recompile your current zshconfig'
    exit 1
    ;;
esac

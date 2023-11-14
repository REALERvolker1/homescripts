[[ $TERM == linux || $TTY == /dev/tty* || -n "${VLKPLUG_SKIP:-}" ]] && return

[[ ! -d "${ZPLUGIN_DIR:=${XDG_DATA_HOME:=$HOME/.local/share}/zsh-plugins}" ]] &&
    mkdir -p "$ZPLUGIN_DIR"

_load_plugin() {
    if [[ -f $1 ]]; then
        zsh-defer . "$1"
        return 0
    elif [[ -e $1 ]]; then
        echo "Skipping plugin ${1##*/} -- not a file!"
        return 0
    else
        return 1
    fi
}

() {
    typeset plug='' fsh='fast-syntax-highlighting' sug='zsh-autosuggestions' fzf='fzf-tab'
    typeset -A fshz=(
        [url]='https://github.com/zdharma-continuum/fast-syntax-highlighting'
        [plugin]="$ZPLUGIN_DIR/$fsh/$fsh.plugin.zsh"
    )
    typeset -A sugz=(
        [url]='https://github.com/zsh-users/zsh-autosuggestions'
        [plugin]="$ZPLUGIN_DIR/$sug/$sug.zsh"
    )
    typeset -A fzfz=(
        [url]='https://github.com/Aloxaf/fzf-tab'
        [plugin]="$ZPLUGIN_DIR/$fzf/$fzf.zsh"
    )

    typeset -a error_plugins=()
    foreach plug (fshz sugz fzfz) {
        typeset -A plugin=("${(Pkv@)plug}")
        _load_plugin $plugin[plugin] && continue
        git clone $plugin[url] ${plugin[plugin]%/*}
        _load_plugin $plugin[plugin] && continue
        error_plugins+=(${plugin[plugin]##*/})
    }

    ((${#error_plugins})) && printf '🟥 %s\n' ${(@)error_plugins}
}

unset -f _load_plugin

__vlk_set_fast_theme() {
    if [[ ${FAST_THEME_NAME:-} != 'vlk-fsyh' ]]; then
        if typeset -f 'fast-theme' &>/dev/null && [[ -f "$ZDOTDIR/settings/vlk-fsyh.ini" ]]; then
            fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
        fi
    fi
    unset -f __vlk_set_fast_theme
}
zsh-defer __vlk_set_fast_theme

if [[ ${TERM-} == linux || ${TTY:-$(tty)} == /dev/tty* || -n ${VLKPLUG_SKIP-} ]]; then
    zmodload zsh/nearcolor # make truecolors behave well in TTY
    return
fi

ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HISTORY_IGNORE="?(#c50,)"

typeset -i __VLKPLUGINS_LOADED=0
__vlkplugin::load() {
    if [[ -f $1 ]]; then
        zsh-defer . "$1"
    elif [[ -e $1 ]]; then
        echo "Skipping plugin ${1:t} -- not a file!"
    else
        return 1
    fi
}

__vlkplugin::refresh() {
    : "${ZPLUGIN_DIR:=${XDG_DATA_HOME:=$HOME/.local/share}/zsh-plugins}"
    [[ ${1-} == '--refresh' ]] && command rm -rf "$ZPLUGIN_DIR"
    [[ ! -d ${ZPLUGIN_DIR-} ]] && command mkdir -p "$ZPLUGIN_DIR"

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
        __vlkplugin::load $plugin[plugin] && continue

        command git clone $plugin[url] ${plugin[plugin]:h}
        __vlkplugin::load $plugin[plugin] && continue

        error_plugins+=(${plugin[plugin]##*/})
    }

    ((${#error_plugins})) && printf '🟥 %s\n' ${(@)error_plugins}
    __VLKPLUGINS_LOADED=1
}
__vlkplugin::refresh
clear

__vlkplugin::fast_theme() {
    if [[ ${FAST_THEME_NAME-} != 'vlk-fsyh' ]]; then
        if [[ "$(whence -w fast-theme)" == *function && -f "$ZDOTDIR/settings/vlk-fsyh.ini" ]]; then
            fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
        fi
    fi
    unset -f __vlkplugin::fast_theme
}
zsh-defer __vlkplugin::fast_theme

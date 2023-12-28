[[ ${VLKZSH_SAFEMODE:-1} -eq 1 || -n ${VLKPLUG_SKIP-} ]] && return

ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HISTORY_IGNORE="?(#c50,)"

__vlkplugin::load() {
    if [[ -f $1 ]]; then
        zsh-defer . "$1"
    elif [[ -e $1 ]]; then
        echo "Skipping plugin ${1:t} -- not a file!"
    else
        return 1
    fi
}
bindkey '^R' .history-incremental-search-backward
bindkey '^S' .history-incremental-search-forward

# to try: https://github.com/marlonrichert/zsh-autocomplete
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
        [branch]=develop
    )
    typeset -A fzfz=(
        [url]='https://github.com/Aloxaf/fzf-tab'
        [plugin]="$ZPLUGIN_DIR/$fzf/$fzf.zsh"
        [cmds]="recompile --all" # build-fzf-tab-module
    )
    typeset -A aucz=(
        [url]='https://github.com/marlonrichert/zsh-autocomplete'
        [plugin]="$ZPLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
    )

    typeset -a error_plugins=()
    foreach plug (fshz sugz fzfz aucz) {
        typeset -A plugin=("${(Pkv@)plug}")
        __vlkplugin::load $plugin[plugin] && continue

        local plugindir=${plugin[plugin]:h}

        command git clone $plugin[url] $plugindir
        if ((${+plugin[branch]})); then
            local prevwd="$PWD"
            builtin cd $plugindir &>/dev/null
            command git checkout $plugin[branch]
            builtin cd $prevwd &>/dev/null
        fi
        if __vlkplugin::load $plugin[plugin]; then
            if ((${+plugin[cmds]})); then
                exec $plugin[cmds]
            fi
        else
            error_plugins+=($plugindir)
        fi
    }

    ((${#error_plugins})) && printf '🟥 %s\n' ${(@)error_plugins}
}
__vlkplugin::refresh

__vlkplugin::keybind_reset() {
    bindkey '^r' _atuin_search_widget
    bindkey '^[[A' _atuin_up_search_widget
    bindkey '^[OA' _atuin_up_search_widget
    bindkey -M viins '^I'  fzf-tab-complete
    bindkey -M viins '^X.' fzf-tab-debug
}
zsh-defer __vlkplugin::keybind_reset

__vlkplugin::fast_theme() {
    if [[ ${FAST_THEME_NAME-} != 'vlk-fsyh' ]]; then
        if [[ "$(whence -w fast-theme)" == *function && -f "$ZDOTDIR/settings/vlk-fsyh.ini" ]]; then
            fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
        fi
    fi
    unset -f __vlkplugin::fast_theme
}
zsh-defer __vlkplugin::fast_theme

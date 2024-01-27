[[ ${VLKZSH_SAFEMODE:-1} -eq 1 || -n ${VLKPLUG_SKIP-} ]] && return

# Some of these plugins can be pretty slow or heavy.
# Avoid loading if my laptop is unplugged
typeset -g __vlkplugin_battery=${$(</sys/class/power_supply/ACAD/online):-0}

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
    typeset -a vlkplugins=()

    # fast-syntax-highlighting
    typeset -A fshz=(
        [url]='https://github.com/zdharma-continuum/fast-syntax-highlighting'
        [plugin]="$ZPLUGIN_DIR/$fsh/$fsh.plugin.zsh"
    )
    vlkplugins+=(fshz)

    # zsh-autosuggestions
    typeset -A sugz=(
        [url]='https://github.com/zsh-users/zsh-autosuggestions'
        [plugin]="$ZPLUGIN_DIR/$sug/$sug.zsh"
        [branch]=develop
    )
    vlkplugins+=(sugz)

    # fzf-tab!! I like I like
    typeset -A fzfz=(
        [url]='https://github.com/Aloxaf/fzf-tab'
        [plugin]="$ZPLUGIN_DIR/$fzf/$fzf.zsh"
        [cmds]="recompile --all" # build-fzf-tab-module
    )
    vlkplugins+=(fzfz)
    
    # zsh-autocomplete. Horrible performance, so I'm disabling it on battery (when battery variable is zero)
    typeset -A aucz=(
        [url]='https://github.com/marlonrichert/zsh-autocomplete'
        [plugin]="$ZPLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
    )
    ((${__vlkplugin_battery:-1})) && vlkplugins+=(aucz)

    typeset -a error_plugins=()
    foreach plug ($vlkplugins) {
        # deserialize the plugin data
        # this system is about as close as you can get to nested associative arrays in zsh
        typeset -A plugin=("${(Pkv@)plug}")
        __vlkplugin::load $plugin[plugin] && continue

        # if the plugin can't load, then run the install part
        local plugindir=${plugin[plugin]:h}

        command git clone $plugin[url] $plugindir
        # choose my chosen git branch, if applicable
        if ((${+plugin[branch]})); then
            local prevwd="$PWD"
            builtin cd $plugindir &>/dev/null
            command git checkout $plugin[branch]
            builtin cd $prevwd &>/dev/null
        fi
        # try to load the plugin again
        if __vlkplugin::load $plugin[plugin]; then
            if ((${+plugin[cmds]})); then
                # run any startup commands
                exec $plugin[cmds]
            fi
        else
            # it could not load successfully
            error_plugins+=($plugindir)
        fi
    }

    # if there are any errors, let me know
    ((${#error_plugins})) && printf '🟥 %s\n' ${(@)error_plugins}
}
__vlkplugin::refresh

# workaround for zsh-autocomplete and fzf-tab/atuin compatibility
__vlkplugin::keybind_reset() {
    bindkey '^r' _atuin_search_widget
    bindkey '^[[A' _atuin_up_search_widget
    bindkey '^[OA' _atuin_up_search_widget

    bindkey -M viins '^I'  fzf-tab-complete
    bindkey -M viins '^X.' fzf-tab-debug
}

# This will run after all the plugins are loaded.
# zsh-autocomplete is very slow, so I might notice that it is still loading 
# when I press the up arrow and see the autocomplete history list instead of atuin.
# Someone should rewrite that shit in rust istg. https://docs.rs/zsh-module/0.3.0/zsh_module/index.html
zsh-defer __vlkplugin::keybind_reset

# set my fast-syntax-highlighting theme if it is not set already
__vlkplugin::fast_theme() {
    if [[ ${FAST_THEME_NAME-} != 'vlk-fsyh' ]]; then
        if [[ "$(whence -w fast-theme)" == *function && -f "$ZDOTDIR/settings/vlk-fsyh.ini" ]]; then
            fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
        fi
    fi
    unset -f __vlkplugin::fast_theme
}
zsh-defer __vlkplugin::fast_theme


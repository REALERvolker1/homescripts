# .zshrc
. "$ZDOTDIR/globals/vlkenv"

# zshrc loading
() {
    local i
    for i in "$ZDOTDIR/rc.d/"*'.zsh'; do
        . "$i"
    done

    [ ! -d "$ZPLUGIN_DIR" ] && zsh-recompile.sh --install-plugins

    local has_defer_plugin=false
    if [ -f "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh" ]; then
        has_defer_plugin=true
        . "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"
    fi

    for i in \
        zcalc \
        zmv \
        "$ZDOTDIR/functions"/^*.zwc(.)
        do
        autoload -Uz "$i"
    done
    . "$ZDOTDIR/globals/vlkrc"

    if ((COLUMNS > 55)); then
        if command -v dumbfetch &>/dev/null; then
            dumbfetch
        fi
        fortune -a -s | (
            if command -v lolcrab &>/dev/null; then
                lolcrab
            elif command -v lolcat &>/dev/null; then
                lolcat
            else
                tee
            fi
        )
    fi
    lsdiff

    for i in \
        "$ZPLUGIN_DIR/atuin.zsh" \
        "$ZPLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" \
        "$ZPLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
        "$ZPLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
        do
        [ ! -f "$i" ] && continue
        if "$has_defer_plugin"; then
            zsh-defer . "$i"
        else
            . "$i"
        fi
    done
} "$@"

if [[ "${FAST_THEME_NAME:-}" != 'vlk-fsyh' ]] && typeset -f 'fast-theme' &>/dev/null; then
    fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
fi
true

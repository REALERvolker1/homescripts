# .zshrc
. "$ZDOTDIR/globals/vlkenv"

# zshrc loading
() {
    local i
    for i in "$ZDOTDIR/rc.d/"*'.zsh'; do
        . "$i"
    done

    [ ! -d "$ZPLUGIN_DIR" ] && zsh-recompile.sh --install-plugins
    . "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"

    for i in \
        zcalc \
        zmv \
        "$ZDOTDIR/functions"/^*.zwc(.)
        do
        autoload -Uz "$i"
    done
    . "$ZDOTDIR/globals/vlkrc"

    ((COLUMNS > 55)) && {
        dumbfetch
        ( fortune -a -s 2>/dev/null || echo '(insert fortune here)' ) | ( lolcrab 2>/dev/null || tee )
    }
    lsdiff

    for i in \
        "atuin.zsh" \
        "fzf-tab/fzf-tab.plugin.zsh" \
        "fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
        "zsh-autosuggestions/zsh-autosuggestions.zsh"
        do
        zsh-defer . "$ZPLUGIN_DIR/$i"
    done
} "$@"

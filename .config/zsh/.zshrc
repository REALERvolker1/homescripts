# .zshrc
. "$ZDOTDIR/globals/vlkenv"

# zshrc loading
() {
    local i
    for i in "$ZDOTDIR/rc.d/"*'.zsh'; do
        . "$i"
    done

    autoload -Uz zcalc

    # autoload -Uz zmv
    # alias zmv='zmv -Mv'
    # alias zln='zmv -Lv'
    # alias zcp='zmv -Cv'

    autoload -Uz "$ZDOTDIR/functions"/^*.zwc(.)

    . "$ZDOTDIR/globals/vlkrc"

} "$@"

# info display
((COLUMNS > 55)) && (
    dumbfetch
    fortune -a -s | lolcrab
)
lsdiff || :

# plugin loading
() {
    [ ! -d "$ZPLUGIN_DIR" ] && zsh-recompile.sh --install-plugins

    . "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"
    local i
    for i in \
        "atuin.zsh" \
        "fzf-tab/fzf-tab.plugin.zsh" \
        "fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
        "zsh-autosuggestions/zsh-autosuggestions.zsh"
        do
        zsh-defer . "$ZPLUGIN_DIR/$i"
    done
}

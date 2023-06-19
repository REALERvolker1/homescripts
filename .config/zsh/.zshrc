# .zshrc
. /home/vlk/bin/vlkenv

# zshrc loading
() {
    local i
    for i in "$ZDOTDIR/rc.d/"*'.zsh'; do
        . "$i"
    done

    . "$HOME/bin/vlkrc"
    . "$ZDOTDIR/prompt.zsh"

} "$@"

# info display
((COLUMNS > 55)) && (
    dumbfetch
    fortune -a -s | lolcrab
)
lsdiff || :

# plugin loading
() {
    printf '%s\n' "${ZSH_PLUGINS[@]}"
    if [ ! -d "${ZPLUGIN_DIR:=${XDG_DATA_HOME:=$HOME/.local/share}/zsh-plugins}" ]; then
        if "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/settings/plugin-install"; then
            echo 'Installed plugins'
        else
            echo 'Failed to install plugins'
            rm -rf "$ZPLUGIN_DIR"
            return 1
        fi
    fi

    . "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"
    local -a async_plugins=(
        "command-sourced.zsh"
        "fzf-tab/fzf-tab.plugin.zsh"
        "fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
        "zsh-autosuggestions/zsh-autosuggestions.zsh"
    )
    for i in "${async_plugins[@]}"; do
        zsh-defer . "$ZPLUGIN_DIR/$i"
    done
}

# zsh-defer . "$ZPLUGIN_DIR/command-sourced.zsh"
# zsh-defer . "$ZPLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
# zsh-defer . "$ZPLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
# zsh-defer . "$ZPLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"

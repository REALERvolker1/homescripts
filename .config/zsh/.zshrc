# .zshrc
. /home/vlk/bin/vlkenv

() {
    local i
    for i in "$ZDOTDIR/rc.d/"*'.zsh'; do
        . "$i"
    done
    . "$HOME/bin/vlkrc"
} "$@"

. "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"

# if [[ "$ICON_TYPE" != 'fallback' ]]; then
#     . "$ZDOTDIR/prompt.zsh"
# fi
. "$ZDOTDIR/prompt.zsh"
((COLUMNS > 55)) && (
    dumbfetch
    fortune -a -s | lolcrab
    #vlk-fortune-rs | lolcrab
)
lsdiff || :

zsh-defer . "$ZPLUGIN_DIR/command-sourced.zsh"
zsh-defer . "$ZPLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
#zsh-defer . "$ZPLUGIN_DIR/fzf-tab-completion/zsh/fzf-zsh-completion.sh" && bindkey '^I' fzf_completion
zsh-defer . "$ZPLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
zsh-defer . "$ZPLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"

# .zshrc
[ -z "${ZSH_VERSION:-}" ] && return
. "$ZDOTDIR/globals/vlkenv"

setopt inc_append_history share_history \
    hist_ignore_all_dups hist_expire_dups_first \
    hist_reduce_blanks hist_no_store hist_ignore_space \
    hist_fcntl_lock extended_history \
    auto_cd auto_pushd pushd_ignore_dups multios \
    extended_glob glob_complete complete_in_word glob_dots interactive_comments \
    prompt_subst nobgnice

HISTFILE="$XDG_STATE_HOME/zshist"
SAVEHIST=50000
HISTSIZE=60000

MAILCHECK=0

# zshrc loading
() {
    alias which='alias | /usr/bin/which --tty-only --read-alias --show-tilde --show-dot'
    export ZPLUGIN_DIR="$XDG_DATA_HOME/zsh-plugins"
    local i
    for i in "$ZDOTDIR/rc.d/"*'.zsh'; do
        . "$i"
    done

    [ ! -d "$ZPLUGIN_DIR" ] && recompile.zsh --install-plugins

    for i in \
        compinit \
        zcalc \
        zmv \
        "$ZDOTDIR/functions"/^*.zwc(.)
        do
        autoload -Uz "$i"
    done
} # "$XDG_CONFIG_HOME/shell/functions/"^*.zwc(.)

. "$ZDOTDIR/globals/vlkpromptrc"
# cat /proc/$$/cmdline | cut -d $'\0' -f 1
. "$ZDOTDIR/globals/vlkrc"

if ((COLUMNS > 55)); then
    command -v dumbfetch &>/dev/null && dumbfetch
    command -v fortune &>/dev/null && fortune -a -s | (
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

() {
    if [ -f "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh" ]; then
        . "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"
        #autoload -Uz "$ZPLUGIN_DIR/zsh-defer/zsh-defer"
    else
        zsh-defer () {$@}
    fi
    local i
    for i in \
        "$ZPLUGIN_DIR/atuin.zsh" \
        "$ZPLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" \
        "$ZPLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
        "$ZPLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
        do
        [ -f "$i" ] || continue
        zsh-defer . "$i"
    done
} "$@"

if [[ "${FAST_THEME_NAME:-}" != 'vlk-fsyh' ]] && typeset -f 'fast-theme' &>/dev/null && [ -f "$ZDOTDIR/settings/vlk-fsyh.ini" ]; then
    fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
fi

# hyperfine -n 5 'zsh -i -c "print -n"'
true

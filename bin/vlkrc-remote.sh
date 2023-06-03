#!/bin/sh
## Disable alias variable expansion complaints
# shellcheck disable=SC2139

case "$-" in
    *i*)
        true
    ;;
    *)
        printf 'Error, must be sourced!\n'
        exit 1
    ;;
esac
if [ "$(uname -o)" != 'GNU/Linux' ]; then
    printf 'Error, your system is not a GNU/Linux operating system!'
    exit 2
fi

VLKRC_BIN="${VLKRC_BIN:-$(readlink -f /bin)}"

export HOME="${HOME:-/home/$USER}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-HOME/.local/state}"

export GPG_TTY="$TTY"

[ -f ~/.gtkrc ] || export GTK_RC_FILES="${GTK_RC_FILES:-$XDG_CONFIG_HOME/gtk-1.0/gtkrc}"
[ -f ~/.gtkrc-2.0 ] || export GTK2_RC_FILES="${GTK2_RC_FILES:-$XDG_CONFIG_HOME/gtk-2.0/gtkrc}"

export LESSHISTFILE="/dev/null"

if command -v nvim >/dev/null; then
    export EDITOR='nvim'
    export MANPAGER='nvim +Man\!'
elif command -v vim >/dev/null; then
    export EDITOR='vim'
elif command -v vi >/dev/null; then
    export EDITOR='vi'
fi
export VISUAL="$EDITOR"

export PAGER='less'

export PATH="$HOME/.bin:$HOME/bin:$HOME/.local/bin:$PATH"

# aliases

ls_opts="$VLKRC_BIN/ls -A --color=auto --group-directories-first"

alias ls="$ls_opts"
alias ll="$ls_opts -l"
alias la="$ls_opts"

unset ls_opts

alias sl=ls
alias l=ls
alias s=ls

alias tree="$VLKRC_BIN/tree --filesfirst"

alias -- -='cd -'

alias q=exit
alias :q=exit

if command -v 'sudo' >/dev/null; then
    unalias sudo 2>/dev/null
    alias suod=sudo
elif command v 'doas' >/dev/null; then
    alias sudo='doas --'
    alias suod='doas --'
else
    echo 'No root helper (eg. sudo, doas) installed!'
fi

if command -v 'systemctl' >/dev/null; then
    alias shutdown='systemctl poweroff'
    alias reboot='systemctl reboot'
else
    alias shutdown='shutdown 0'
    unalias reboot
fi

alias grep="$VLKRC_BIN/grep --color=auto"
alias egrep="$VLKRC_BIN/egrep --color=auto"
alias igrep="$VLKRC_BIN/grep -i --color=auto"

if command -v trash >/dev/null; then
    alias rm='trash'
else
    alias rm="$VLKRC_BIN/rm -i -r"
fi
alias rmf="$VLKRC_BIN/rm -rf"

alias chmodx='chmod +x'
alias chmod-x='chmod -x'

alias free='free -m'

alias vi='$EDITOR'
#alias vim='$EDITOR'
alias ivm='$EDITOR'
alias iv='$EDITOR'
alias v='$EDITOR'
alias svim=sudoedit

alias whihc=which

alias wget='wget --show-progress'

command -v xprop >/dev/null && alias xclassget='xprop | grep WM_CLASS'
command -v xev >/dev/null && alias xkeyget="xev -event keyboard | egrep -o 'keycode.*\)'"

if command -v fzf >/dev/null; then
    alias fenv='printenv | fzf'

    psa () {
        /usr/bin/ps -eo pid,comm,exe h | /usr/bin/fzf -q "${1:- }"
    }
fi

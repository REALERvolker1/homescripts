
export ZPLUGIN_DIR="$XDG_DATA_HOME/zsh-plugins"
export DUMBFETCH_SHELL=zsh

hash -d zsh="$ZDOTDIR"
hash -d bin="$HOME/bin"
hash -d code="$HOME/code"
hash -d pics="$HOME/Pictures"
hash -d dots="$HOME/dotfiles"

hash -d loc="$HOME/.local"
hash -d data="$XDG_DATA_HOME"
hash -d cache="$XDG_CACHE_HOME"
hash -d cfg="$XDG_CONFIG_HOME"

hash -d i3="$XDG_CONFIG_HOME/i3"
hash -d i3s="$XDG_CONFIG_HOME/i3status-rust"
hash -d hypr="$XDG_CONFIG_HOME/hypr"


fpath=(
    "$ZDOTDIR/site-functions"
    "$ZPLUGIN_DIR/zsh-completions/src"
    $fpath
)

export -U PATH path FPATH fpath MANPATH manpath

export -U XDG_DATA_DIRS
export -U chpwd_functions

READNULLCMD="$PAGER"

__cd_ls () {
    lsd
}
chpwd_functions+=('__cd_ls')

PROMPT='%k%f
%B %F{14}%~%f %(0?.%F{10}%#.%F{9}%? %#) %b%f'
#RPS1='%(0?..%F{9}%B%?%b)'
ZLE_RPROMPT_INDENT=0
PROMPT_EOL_MARK=''

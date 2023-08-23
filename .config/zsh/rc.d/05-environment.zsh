hash -d zsh="$ZDOTDIR"
hash -d bin="$HOME/bin"
hash -d code="$HOME/code"
hash -d pics="$HOME/Pictures"
hash -d var="$HOME/.var/app"
[ -d "${HOMESCRIPTS:-}" ] && hash -d dots="$HOMESCRIPTS"

hash -d loc="$HOME/.local"
hash -d data="$XDG_DATA_HOME"
hash -d cache="$XDG_CACHE_HOME"
hash -d cfg="$XDG_CONFIG_HOME"
hash -d run="$XDG_RUNTIME_DIR"

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

export ZSH_PLUGINS="https://github.com/romkatv/zsh-defer
https://github.com/Aloxaf/fzf-tab
https://github.com/zdharma-continuum/fast-syntax-highlighting
https://github.com/zsh-users/zsh-autosuggestions"

READNULLCMD="$PAGER"

__cd_ls() {
    declare -i fcount="$($(which --skip-alias ls) -A1 | wc -l)"
    if ((fcount < 30)); then
        lsd
    else
        echo -e "\e[${${${LS_COLORS:-01;34}##*:di=}%%:*}m${fcount}\e[0m items in this folder"
    fi
}
chpwd_functions+=('__cd_ls')

PROMPT='%k%f
%B %F{14}%~%f %(0?.%F{10}%#.%F{9}%? %#) %b%f'
ZLE_RPROMPT_INDENT=0
PROMPT_EOL_MARK=''

alias -s {css,gradle,html,js,json,md,patch,properties,txt,xml,yml}="bat --paging always"
alias -s gz='gzip -l'
alias -s {log,out}='tail -F'

# aliasrc

hr_color () {
    local i
    for ((i=0;i<COLUMNS;i++)); {
        printf '\033[10%sm \033[0m' "$(( ( RANDOM % 7 )  + 1 ))"
    }
}

zl () {
    export ZDOTDIR="$HOME/.config/zsh/zsh-launchpad"
    exec zsh
}

alias refresh=". $HOME/bin/vlkenv && . $HOME/bin/vlkrc && rehash"
alias uncompile='recompile --uncompile'

alias hr='printf "%*s\n" "${COLUMNS:-$(tput cols)}" "" | tr " " -'

alias %= \$=

alias -s {css,gradle,html,js,json,md,patch,properties,txt,xml,yml}="bat --paging always"
alias -s gz='gzip -l'
alias -s {log,out}='tail -F'

autoload -Uz zcalc

autoload -Uz zmv
alias zmv='zmv -Mv'
alias zcp='zmv -Cv'
alias zln='zmv -Lv'

autoload -Uz "$ZDOTDIR/functions/"*(.)

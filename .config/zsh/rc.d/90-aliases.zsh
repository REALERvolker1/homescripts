# aliasrc

alias uncompile='recompile --uncompile'



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

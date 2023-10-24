[[ -n $ZSH_VERSION && -z $ZSHRC_LOADED && $- == *i* ]] || {
    echo "failed to load zshrc"
    return 1
    exit 1
}
emulate -LR zsh

# cmdarr=("${(@)commands##*/}")
### shell session settings
# VLKPROMPT_SKIP=1
# VLKZSH_RECOMPILE=1
# VLKZSH_LSDIFF_UPDATE=1

foreach i ("$ZDOTDIR/rc.d"/*.zsh) {
    if [[ $i == *.defer.zsh ]] {
        zsh-defer . "$i"
    } else {
        . "$i"
    }
}
unset i
((${+VLKZSH_RECOMPILE})) && echo "Recompiling..." && recompile >/dev/null
((COLUMNS > 55)) && startup-print

ZSHRC_LOADED=true
true

# .zshrc
if [[ -n $ZSH_VERSION && -z $ZSHRC_LOADED && $- == *i* ]]; then
    emulate -LR zsh
else
    echo "failed to load zshrc"
    return 1
    exit 1
fi

# shell session settings
#VLKPROMPT_SKIP=1
#VLKZSH_RECOMPILE=1

for i in "$ZDOTDIR/rc.d"/*.zsh; do
    if [[ "$i" == *.defer.zsh ]]; then
        zsh-defer . "$i"
    else
        . "$i"
    fi
done
unset i
((${+VLKZSH_RECOMPILE})) && echo "Recompiling..." && zcompile "$i"
((COLUMNS > 55)) && {
    dumbfetch # should complete while other one is loading
    (fortune -a -s | lolcat &)
    lsdiff
}

ZSHRC_LOADED=true
true

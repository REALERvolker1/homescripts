[[ -n $ZSH_VERSION && -z $ZSHRC_LOADED && $- == *i* ]] || {
    echo "failed to load zshrc"
    return 1
    exit 1
}
emulate -LR zsh
set +euo pipefail

if [[ $IFS != $' \t\n\C-@' ]]; then
    echo -n 'Non-default IFS: '
    declare IFS
    echo "Resetting IFS"
    IFS=$' \t\n\C-@'
fi

# Idea: debug mode function. When run, it adds useful stuff like lines/cols
# and persistent exec time and whatever to my prompt

### shell session settings
# VLKPROMPT_SKIP=1
# VLKPLUG_SKIP=1
# VLKZSH_RECOMPILE=1

# Certain files like vlkrc and vlkenv from ~/bin are loaded along with other settings files

foreach i ("${ZDOTDIR:-~/.config/zsh}/rc.d"/*.zsh) {
    #[[ $i == *prompt* ]] && continue
    #[[ $i == *plugins* ]] && continue
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
:

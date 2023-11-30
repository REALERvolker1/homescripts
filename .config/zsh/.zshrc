[[ -n ${ZSH_VERSION-} && -z ${ZSHRC_LOADED-} && $- == *i* ]] || {
    echo "failed to load zshrc"
    return 1
    exit 1
}
emulate -LR zsh
set +euo pipefail
ZSHRC_LOADED=false

if [[ $IFS != $' \t\n\C-@' ]] {
    declare IFS
    echo 'Resetting non-default IFS'
    IFS=$' \t\n\C-@'
}

# Idea: debug mode function. When run, it adds useful stuff like lines/cols
# and persistent exec time and whatever to my prompt

### shell session settings
# VLKPROMPT_SKIP=1
# VLKPLUG_SKIP=1
# VLKZSH_RECOMPILE=1

# Certain files like vlkrc and vlkenv from ~/bin are loaded along with other settings files

foreach i ("${ZDOTDIR:-~/.config/zsh}/rc.d"/*.zsh) {
    if [[ $i == *.defer.zsh ]] {
        zsh-defer . "$i"
    } else {
        . "$i"
    }
}
unset i
((${+VLKZSH_RECOMPILE})) && echo "Recompiling..." && recompile >/dev/null
echo -en '\e[0H' # clear the sccreen
if ((COLUMNS > 55)) {
    dumbfetch
    fortune -a -s | lolcat
    lsdiff
}

ZSHRC_LOADED=true
:


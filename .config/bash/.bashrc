# .bashrc
# shellcheck shell=bash disable=1090,1091

if [[ -n $BASH_VERSION && -z $BASHRC_LOADED && $- == *i* ]]; then
    true
else
    return
    exit
fi
BASHRC_LOADED=true
# [[ 1 ]] || return
shopt -s autocd cdspell cmdhist checkwinsize histappend
bind "set completion-ignore-case on"

for i in \
    '/etc/bashrc' '/etc/bash.bashrc' \
    "$HOME/bin/vlkenv" \
    /etc/profile.d/bash_completion.sh \
    "$HOME/bin/vlkrc"; do
    [[ -f "$i" ]] && . "$i"
done
unset i
# "$HOME/bin/vlkpromptrc" \

if [[ -n ${PS1:-} && -z ${BASH_COMPLETION_VERSINFO:-} && ${BASH_VERSINFO[0]} -gt 4 ]]; then
    [[ -r ${BDOTDIR:-$HOME}/bash_completion ]] && . "${BDOTDIR:-$HOME}/bash_completion"
    shopt -q progcomp && [[ -r /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
fi

export BPLUGIN_DIR="$XDG_DATA_HOME/bash-plugins"
if [[ ! -f "$BPLUGIN_DIR/blesh/out/ble.sh" ]] && command -v git &>/dev/null; then
    echo -e "\e[1mCloning ble.sh\e[0m"
    __ble_cwd="$PWD"
    mkdir -p "$BPLUGIN_DIR/blesh" || return
    git clone 'https://github.com/akinomyoga/ble.sh.git' "$BPLUGIN_DIR/blesh"
    builtin cd "$BPLUGIN_DIR/blesh" || return
    make
    builtin cd "$__ble_cwd" || return
    unset __ble_cwd
fi
[[ -f "$BPLUGIN_DIR/blesh/out/ble.sh" ]] && . "$BPLUGIN_DIR/blesh/out/ble.sh" --noattach
if command -v atuin &>/dev/null && [[ $TERM != linux ]]; then
    . <(atuin init bash)
fi

[[ "${HOSTNAME:=$(hostname)}" != "${CURRENT_HOSTNAME:-ud}" ]] && hcol="@\[\e[94m\]\H\[\e[0m\]"
PS1="\[\e[0m\]\n\$(r=\"\$?\";((r>0))&&echo \"\[\e[1;91m\]\$r\[\e[0m\] \")\[\e[1m\][\[\e[0;92m\]\u\[\e[0m\]${hcol:-}\[\e[1m\]]\[\e[0m\]\[\e[${DIRECTORY_COLOR:=1;34}m\] \w \[\e[0m\]$ "
unset PROMPT_COMMAND hcol

HISTFILE="$XDG_STATE_HOME/bash_history"
HISTCONTROL='erasedups:ignoreboth'

printf '%s -%s' "${0##*/}" "$-" | (
    if command -v figlet &>/dev/null; then
        figlet -f smslant -w "$COLUMNS"
    else
        tee
    fi
) | (
    if command -v lolcat &>/dev/null; then
        lolcat
    else
        tee
    fi
)

[[ ${BLE_VERSION:-} ]] && ble-attach
true

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/etc/profile.d/conda.sh" ]; then
        . "/usr/etc/profile.d/conda.sh"
    else
        export PATH="/usr/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


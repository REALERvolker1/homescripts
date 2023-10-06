# .bashrc
# shellcheck shell=bash disable=1090,1091

if [[ -n $BASH_VERSION && -z $BASHRC_LOADED && $- == *i* ]]; then
    true
else
    echo "Could not source bashrc"
    return
    exit
fi
# [[ 1 ]] || return
shopt -s autocd cdspell cmdhist checkwinsize histappend
bind "set completion-ignore-case on"

for i in \
    '/etc/bashrc' '/etc/bash.bashrc' \
    "$HOME/bin/vlkenv" \
    "$HOME/bin/vlkrc"; do
    [[ -f "$i" ]] && . "$i"
done
unset i
# "$HOME/bin/vlkpromptrc" \

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

# temporary fix copied directoy from my dashrc
if command -v lscolors >/dev/null 2>&1; then
    _colorhome="$(lscolors "$HOME" | sed 's|/.*|~|')"
    __wdprint() {
        # dash supports the `local` keyword for some reason
        local __trailing_slash
        [ "${PWD:=NULLPWD}" != "$HOME" ] && __trailing_slash='/'
        case "$PWD" in
        "$HOME"*)
            echo "${_colorhome}${__trailing_slash:-}$(lscolors "$PWD" | grep -oP '/[^/]*/[^/]*/\K.*')"
            ;;
        *)
            lscolors "$PWD"
            ;;
        esac
    }
else
    __wdprint() {
        case "${PWD:=NULLPWD}" in
        "$HOME"*)
            echo "$PWD" | sed "s|${HOME}|~|"
            ;;
        *)
            echo "$PWD"
            ;;
        esac
    }
fi
PS1='$(__wdprint) $ '

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
BASHRC_LOADED=true
true

#!/usr/bin/bash
# shellcheck shell=bash
# a script that does a thing.
set -euo pipefail
IFS=$'\n\t'

# useful functions
_panic() {
    printf '[0m%s[0m\n' "$@" >&2
    exit 1
}

_prompt() {
    local answer
    printf '%s\n' "$@"
    read -r -p "[y/N] > " answer
    if [[ ${answer:-} == y ]]; then
        return 0
    else
        return 1
    fi
}

_array_join() {
    local ifsstr=$'\n'
    if [[ "${1:-}" == '--ifs='* ]]; then
        ifsstr="${1#*=}"
        shift 1
    fi
    local oldifs="${IFS:-}"
    local IFS="$ifsstr"
    echo "$*"
    IFS="$oldifs"
}

_strip_color() {
    # Strip all occurences of ansi color strings from input strings
    # uncomment matches to do stuff with the strings themselves
    local ansi_regex='\[([0-9;]+)m'
    local i
    # local -a matches=()
    for i in "$@"; do
        while [[ $i =~ $ansi_regex ]]; do
            # matches+=("${BASH_REMATCH[1]}")
            i=${i//${BASH_REMATCH[0]}/}
        done
        echo "$i"
    done
}

# box-drawing characters, powerline characters, and some other nerd font icons, useful for output
#╭─┬─╮│    󰀄  󰕈
#├─┼─┤│   󰓎 󰘳  󰂽
#╰─┴─╯│   󰅟 󰘲 󰣇 󰣛
# 󰬛󰬏󰬌 󰬘󰬜󰬐󰬊󰬒 󰬉󰬙󰬖󰬞󰬕 󰬍󰬖󰬟 󰬑󰬜󰬔󰬗󰬌󰬋 󰬖󰬝󰬌󰬙 󰬛󰬏󰬌 󰬓󰬈󰬡󰬠 󰬋󰬖󰬎

# dependency check
declare -a faildeps=()
for i in jq grep wc date; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing dependencies:" "${faildeps[@]}"

updatefile="$XDG_RUNTIME_DIR/${0##*/}.json"

# argparse
declare -a config_backends=()
declare -i DAEMON=0
declare -i UPDATE=0

for i in "$@"; do
    case "${i:=}" in
    --pacman)
        config_backends+=(pacman)
        ;;
    --flatpak)
        config_backends+=(flatpak)
        ;;
    --dnf)
        config_backends+=(dnf)
        ;;
    --cargo)
        config_backends+=(cargo)
        ;;
    --auto)
        config_backends=()
        ;;
    --daemon)
        DAEMON=1
        ;;
    --print)
        DAEMON=0
        UPDATE=0
        ;;
    --update)
        DAEMON=0
        UPDATE=1
        ;;
    *)
        echo "
Error, invalid arg passed! '$i'

--auto       Autodetect which backends you have installed (default)
    Any forced backend args will override this, and only show the specified backend(s).

Force backends with the following:
--pacman     enable pacman backend (requires 'checkupdates' from pacman-contrib)
--flatpak    enable flatpak backend
--dnf        enable dnf backend
--cargo      enable cargo-update backend

--daemon     Run in the background, automatically updating a file at $updatefile
--print      Print the (parsed) contents of the updatefile. Will create it if it does not exist.
    This is the default behavior
--update     Update the contents of the updatefile

Example
${0##*/} --pacman --flatpak
This checks the pacman and flatpak backends for updates.
"
        exit 2
        ;;
    esac
done

# autodetect backends if unset
if [[ -n "${config_backends:-}" ]]; then
    echo "Overriding backends"
    printf '%s ' "${config_backends[@]}"
    echo
else
    if command -v pacman checkupdates &>/dev/null; then
        config_backends+=(pacman)
    fi
    if command -v flatpak &>/dev/null; then
        config_backends+=(flatpak)
    fi
    if command -v dnf &>/dev/null; then
        config_backends+=(dnf)
    fi
    if command -v cargo-install-update &>/dev/null; then
        config_backends+=(cargo)
    fi
fi

((${#config_backends})) || _panic "Error, no backends to choose from!"

update::pacman() {
    checkupdates | wc -l 2>/dev/null
}
update::flatpak() {
    flatpak remote-ls --updates | wc -l 2>/dev/null
}
update::dnf() {
    dnf check-update | wc -l 2>/dev/null
}
update::cargo() {
    cargo install-update -ag -l | grep -ic 'yes$' 2>/dev/null
}

# using eval here will make it so I don't do a ton of processing at runtime
evalstr="echo \""
for i in "${config_backends[@]}"; do
    evalstr="$evalstr
\\\"$i\\\": \$(update::$i),"
done
evalstr="$evalstr
\\\"checktime\\\": \$(date +'%H')
}\""

_update_updates() {
    [[ -t 1 ]] && echo "Checking for updates..."
    (
        eval "$evalstr"
    ) >"$updatefile"
}

set +euo pipefail

[[ ! -f "$updatefile" ]] && _update_updates

if ((UPDATE)); then
fi

# eval "$evalstr"
# echo "{\"lastcheck\":$(date +'%H'),\"pacman\":$(checkupdates | wc -l),\"flatpak\":$(flatpak remote-ls --updates | wc -l)}"

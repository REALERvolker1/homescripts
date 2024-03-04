#!/usr/bin/env bash
# shellcheck shell=bash #disable=2034
# a script by vlk to do a thing.

## Copyright (C) 2023 vlk
## This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
## This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

declare -r ME="${0##*/}"
declare -r PROGNAME="${ME%%.*}"
declare -r PROGVERS='0.0.1'

# function to put bash in either safe or unsafe mode
__mode() {
    if [[ "${1:-}" == '--unsafe-mode' ]]; then
        set +euo pipefail
    else
        set -euo pipefail
        IFS=$'\n\t'
    fi
}

# some useful characters
declare -r TAB=$'\t'
declare -r LF=$'\n'
declare -r ESC=''

# box-drawing characters, powerline characters, and some other nerd font icons, useful for output
#╭─┬─╮│    󰀄  󰕈
#├─┼─┤│   󰓎 󰘳  󰂽
#╰─┴─╯│   󰅟 󰘲 󰣇 󰣛
# 󰬛󰬏󰬌 󰬘󰬜󰬐󰬊󰬒 󰬉󰬙󰬖󰬞󰬕 󰬍󰬖󰬟 󰬑󰬜󰬔󰬗󰬌󰬋 󰬖󰬝󰬌󰬙 󰬛󰬏󰬌 󰬓󰬈󰬡󰬠 󰬋󰬖󰬎
# set it in safe mode, a reasonable default
__mode

# determine a safe output to print to
declare -i MYTTY=0
declare -i PIPE_BOTH=0
declare -i PIPEOUTPUT=0
if [[ -t 1 && -t 2 ]]; then
    MYTTY=1
elif [[ -t 1 && ! -t 2 ]]; then
    MYTTY=1
    PIPEOUTPUT=2
elif [[ ! -t 1 && -t 2 ]]; then
    MYTTY=2
    PIPEOUTPUT=1
else
    PIPE_BOTH=1
fi
declare -r MYTTY
declare -r PIPEOUTPUT
declare -r PIPE_BOTH

_log() {
    # split content with IFS
    local IFS=$'\n'
    local content="$*"
    ((MYTTY)) && echo "[0m$content[0m" >&"$MYTTY"
    if ((PIPE_BOTH)); then
        echo "$content"
        echo "$content" >&2
    elif ((PIPEOUTPUT)); then
        echo "$content" >&"$PIPEOUTPUT"
    fi
}

# add main system binary folder to path if it isn't there already
[[ ":${PATH:-}:" != *':/usr/bin:'* ]] && PATH="${PATH}:/usr/bin"

# panic function, to gracefully tell the user what went wrong
_panic() {
    _log "[$ME] panic!" "$@"
    # uncomment if you want to send a desktop notification
    # [[ -n ${DISPLAY:-} || -n ${WAYLAND_DISPLAY:-} ]] && notify-send -i 'dialog-error' -a "${0##*/}" 'Panic!' "$content"
    exit 1
}

# check for dependencies
declare -a faildeps=()
for i in 'notify-send' sed grep; do
    command -v $i &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic 'Missing dependencies' "${faildeps[@]}"

# Example arg parsing, you don't have to do all this

_print_help() {
    cat <<HELP
$PROGNAME $PROGVERS
$ME invalid arg: '$i'

Available options:

--ansi (-a)         Use ansi colors
    --no-ansi       Do not use ansi colors

--prefix="string"   Use a prefix string
    -p "string"     Use a prefix string (alternate form)

--header (-h)       Set header
--config (-c)       Read config file

/path/to/file       A file path
-                   Read file path from stdin
--                  Any arguments after this are considered as file paths

HELP
}

# maybe an environment variable override?
OVERRIDE_CONFIG=''

declare -A config=(
    [ansi]=1
    [prefix]=''
    [color]=92
    [header]='Head'
    # [config_file]="${TEMPLATE_CONFIG_HOME:=$XDG_CONFIG_HOME/$ME_NO_DOT/config}"
)

printf -v config_keys '%s:' "${!config[@]}"

declare -a files=()
last_key=''
declare -i ignore_keys=0
for i in "$@"; do
    if ((ignore_keys)); then
        files+=("$i")
    elif [[ -n ${last_key:-} ]]; then
        case "$last_key" in
        header)
            config[header]="$i"
            ;;
        prefix)
            config[prefix]="$i"
            ;;
        config)
            ARG_OVERRIDE_CONFIG="$i"
            ;;
        esac
        last_key=''
    else
        # uncomment and use if you are using mostly --key=val args
        # [[ ${i:-} == *'='* ]] && i_val="${i#*=}"
        case "${i:=}" in
        --ansi | -a)
            config[ansi]=1
            ;;
        --no-ansi)
            config[ansi]=0
            ;;
        --prefix=*)
            config[prefix]="${i#*=}" # or "$i_val"
            ;;
        -p)
            last_key=prefix
            ;;
        --header | -h)
            last_key=header
            ;;
        --config | -c)
            last_key=config
            ;;
        --)
            ignore_keys=1
            ;;
        -)
            [[ -t 0 && $MYTTY -ne 0 ]] && echo "Reading line from stdout" >&"$MYTTY"
            read -r line
            files+=("$line")
            unset line
            ;;
        -*)
            if [[ -e "$i" ]]; then
                files+=("$i")
            else
                # they could have just been running cmd --help
                _print_help
                exit 2
            fi
            ;;
        esac
    fi
done
[[ -n ${last_key:-} ]] && _panic "Missing value for key '$last_key'"
((${#files[@]})) && _panic "Error, select some files!"

_load_config() {
    # config parser for key=value config file
    # [Section Header]
    # # comment
    # key=val
    # key2=val2
    for j in "$@"; do
        [[ -f "$j" && -r "$j" ]] || return

        local -A tmpconfig=()

        local current_header=''
        local line key val i
        while IFS= read -r line; do
            case "${line:=}" in
            '' | '#'*) continue ;;
            '['*']')
                current_header="${line:1:-1}"
                ;;
            '['* | *']')
                _log "Expected valid [Header], got '$line' instead"
                ;;
            *'='*) : ;;
            *)
                _log "Expected key=value, got '$line' instead"
                ;;
            esac
            key="${line%%=*}"
            val="${line#*=}"
            if [[ -n "${current_header:-}" ]]; then
                tmpconfig[$current_header]="${tmpconfig[$current_header]}"$'\t'"$key=$val"
            else
                tmpconfig[$key]="$val"
            fi
        done <"$j"
        unset current_header line key val
        for i in "${!tmpconfig[@]}"; do
            if [[ ":${config_keys}:" == *":${i}:"* ]]; then
                config[$i]="${tmpconfig[$i]}"
            else
                _log "key '$i' not found in config!"
            fi
        done
    done
    no_config=0
}

declare -i no_config=1
# comprehensive glob of pretty much all config file endings I can think of
declare -a possible_config_files=({"${XDG_CONFIG_HOME:-$HOME/.config}/","$HOME/"{,.},/etc/}{"$PROGNAME"{{.conf,}.d,}/{"$PROGNAME",config},"$PROGNAME"}{,.ini} "${ARG_OVERRIDE_CONFIG:-null}" "${OVERRIDE_CONFIG:-null}")

# printf '%s\n' "${possible_config_files[@]}"
_load_config "${possible_config_files[@]}" || :

# setting no_config is a side effect of _load_config
no_config=0
if ((no_config)); then
    cfg_file="${XDG_CONFIG_HOME:-$HOME/.config}/$PROGNAME/config"
    mkdir -p "${cfg_file%/*}"
    touch -- "$cfg_file"
    _log 'Making new config file' "$cfg_file"
    for i in "${!config[@]}"; do
        printf '%s=%s\n' "$i" "${config[$i]}" >"$cfg_file"
    done
    unset cfg_file
fi

# colored text example
colortext="$(bat "$HOME/bin/dumbfetch.sh")"

_strip_color() {
    # Strip all occurences of ansi color strings from input strings
    local ansi_regex='\[([0-9;]+)m'
    local i
    local -a matches=()
    for i in "$@"; do
        while [[ $i =~ $ansi_regex ]]; do
            matches+=("${BASH_REMATCH[1]}")
            i=${i//${BASH_REMATCH[0]}/}
        done
        echo "$i"
    done
}

# thanks, https://github.com/dylanaraps/pure-bash-bible
_reverse_array() {
    # Usage: reverse_array "array"
    shopt -s extdebug
    f() (printf '%s\n' "${BASH_ARGV[@]}")
    f "$@"
    shopt -u extdebug
}
cycle() {
    printf '%s ' "${arr[${i:=0}]}"
    ((i = i >= ${#arr[@]} - 1 ? 0 : ++i))
}

# mapfile -t file_data <"$HOME/.bashrc"
# declare -n ref=hello_$var

# echo "${colortext///}"
# 
# old attempts
# [[ $colortext =~ ([0-9\;]+m) ]]
# printf '%s\n' "${BASH_REMATCH[@]}"
# echo "${colortext//[[0-9;]*/}"
# echo "${colortext//[[0-9;]/}"

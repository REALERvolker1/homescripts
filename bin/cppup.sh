#!/usr/bin/env bash

# Copyright (C) 2025  REALERvolker1
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -euo pipefail
IFS=$'\r\n'

declare -i fd=0
for i in stty tput mkdir cmake cc cpp; do
    hash "$i" || fd=1
done
((fd)) && exit 13 || :
unset fd i

tput init

panic() {
    printf '%s\n' "$@"
    exit 1
}

prompt::string() {
    local prompt=''
    local outvar=RESULT
    local default=''

    local -i state=0
    local i

    for i in "$@"; do
        case $state in
        0)
            case "${i:-}" in
                --prompt) state=1 ;;
                --outvar) state=2 ;;
                --default) state=3 ;;
            esac
            continue
            ;;
        1) prompt="$i" ;;
        2) outvar="$i" ;;
        3) default="$i" ;;
        esac
        state=0
    done

    local -n outvar_n="$outvar"

    read -r -p"$prompt" outvar_n

    if [[ -z "${outvar_n}" ]]; then
        outvar_n="$default"
    fi
}

# shellcheck disable=SC2120
prompt::bool() {
    local -i default=1
    local prompt='[y/N] > '

    if (($#)); then
        default=0
        prompt='[Y/n] > '
    fi

    local ans='hj'

    for ((;;)); do
        case "${ans,,}" in
            y|ye|yes|true|t|1|on) return 0 ;;
            n|no|false|f|0|off) return 1 ;;
            '') return $default ;;
            *) read -r -p"$prompt" ans ;;
        esac
    done
}

prompt::string --prompt 'greer?' --outvar vargreer --default defaultbruh

echo "
out: $vargreer"

if prompt::bool; then
    echo ye "$?"
else
    echo na "$?"
fi

exit

prompt_usern() {
    local prompt="$1"
    local default="${3:-}"
    local -n outvar="$2"

    if ((${#default})); then
        # Original: "$1${2:+ ("$2")}"
        # This does the same exact thing, but it is more readable
        prompt="$prompt ($default)"
    fi

    read -r -p $'\e[0;2;3m'"$prompt"$'\e[0;1m >\e[0m ' outvar

    if [[ -z "${outvar:-}" && ${#default} ]]; then
        # replace with default if user did not select anything
        outvar="$default"
    fi
}



declare -r ESC=$'\e'
declare -r CLR="$(tput clear)"
declare -r HMPOS="${ESC}[H"
declare -r U1="${ESC}[A"
declare -r D1="${ESC}[B"
declare -r R1="${ESC}[C"
declare -r L1="${ESC}[D"
declare -r ALT_I="$(tput smcup)"
declare -r ALT_O="$(tput rmcup)"
declare -r CURSOR_ON="$(tput cnorm)"

# https://unix.stackexchange.com/questions/179191/bashscript-to-detect-right-arrow-key-being-pressed
read_input() {
    local -i selection_idx=0
    local -i max_idx=$(($# - 1))
    local render_rst="${CLR}${HMPOS}$(($# + 2))"

    local swp=''

    printf '\e[?25l'

    echo 'use WASD / arrow keys / HJKL to move, SPACE to select, or Q to exit.'

    while read -rsn1 swp; do
        case "${swp:=}" in
            $'\e')
                read -rsn1 -t 0.1 swp || :
                if [[ ${swp:=} == '[' ]]; then
                    read -rsn1 -t 0.1 swp || :
                    case "${swp:=}" in
                    A) echo w ;;
                    B) echo s ;;
                    C) echo d ;;
                    D) echo a ;;
                    esac
                fi

                read -rsn5 -t 0.1 || : # flush
                ;;
            w | W | k | K) echo w ;;
            s | S | j | J) echo s ;;
            a | A | h | H) echo a ;;
            d | D | l | L) echo d ;;

            ' ')
                echo ' '
                ;;

            q | Q) break ;;
        esac
    done

    printf '\e[?25h'
    printf '\e[0;1;3m%s\n\e[0m' "${choices[$selection_idx]}"
}


read_input ISC MPL GPL-3.0-only

echo 'The basics of your project'
prompt_user 'Project Name'  name "${PWD##*/}"
prompt_user 'version'       version '0.0.1'
prompt_user 'Description'   desc

echo '
Choose your license. Go to https://spdx.org/licenses/ for a convenient list.'
prompt_user 'License'       license 'ISC'

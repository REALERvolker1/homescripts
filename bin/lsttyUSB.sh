#!/usr/bin/env bash
# shellcheck shell=bash
# a script that tells you which USB serial devices are connected. Might miss some though...
set -euo pipefail
shopt -s extglob globstar nullglob nocaseglob dotglob
IFS=$'\n\t'

# useful functions
util::panic() {
    printf '[0m%s[0m\n' "$@" >&2
    exit 1
}

util::prompt() {
    local answer
    printf '%s\n' "$@"
    read -r -p "[y/N] > " answer
    if [[ ${answer:-} == y ]]; then
        return 0
    else
        return 1
    fi
}

util::array_join() {
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

# box-drawing characters, powerline characters, and some other nerd font icons, useful for output
#╭─┬─╮│    󰀄  󰕈
#├─┼─┤│   󰓎 󰘳  󰂽
#╰─┴─╯│   󰅟 󰘲 󰣇 󰣛
# 󰬛󰬏󰬌 󰬘󰬜󰬐󰬊󰬒 󰬉󰬙󰬖󰬞󰬕 󰬍󰬖󰬟 󰬑󰬜󰬔󰬗󰬌󰬋 󰬖󰬝󰬌󰬙 󰬛󰬏󰬌 󰬓󰬈󰬡󰬠 󰬋󰬖󰬎

# argparse
declare -A config=(
    [dir]='/dev'
)

for i in "$@"; do
    case "${i:=}" in
    --dir=)
        config[dir]="${i#*=}"
        ;;
    *)
        cat <<BRUH
Error, invalid arg passed! '$i'

Valid arguments include:
--dir='text'  Choose which directory to use. Defaults to /dev.

BRUH
        exit 2
    esac
done

app::print_entries() {
    printf '%s\n' "${config[dir]}"/ttyU* || :
    printf '%s\n' "${config[dir]}"/ttyA* || :
}

echo -n "Printing USB TTY entries of ${config[dir]} with "

if command -v ls-colors; then
    app::print_entries | ls-colors
elif command -v lscolors; then
    app::print_entries | lscolors
elif command -v ls; then
    app::print_entries | while read -r line; do
        ls --color=always -AdN1 "$line" || :
    done
    exit "$?"
else
    echo 'no colors! (No coloring command was found)'
    app::print_entries
    exit "$?"
fi

#!/usr/bin/bash
# shellcheck shell=bash
# a script that extracts a compressed archive
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

# thanks a ton to https://github.com/dylanaraps/pure-bash-bible
urlencode() {
    # Usage: urlencode "string"
    local LC_ALL=C
    local i
    for ((i = 0; i < ${#1}; i++)); do
        : "${1:i:1}"
        case "$_" in
        [a-zA-Z0-9.~_-])
            printf '%s' "$_"
            ;;

        *)
            printf '%%%02X' "'$_"
            ;;
        esac
    done
    # printf '\n'
}

_delete_forever() {
    local filepath="${1:?Error, please select file to add to trash!}"
    local -i confirm=0
    [[ "${2-}" == --confirm ]] && confirm=1
    if ((confirm)) || _prompt "Delete filepath '$filepath' forever? (a really long time)"; then
        echo "Deleting --- $filepath"
        rm -rf "$filepath"
    else
        echo "Skipping ---"
        return
    fi
}

# _send_trash() {
#     local filepath="${1:?Error, please select file to add to trash!}"

#     # xdg says if you don't have it in your $HOME, it can't be removed
#     if [[ "${filepath:-}" != "${HOME:-}"* ]]; then
#         echo "Error, could not trash file path '$filepath'!"
#         _delete_forever "$filepath"
#         return
#     elif _prompt "Trash filepath '$filepath'?"; then
#         local filepath_urlencode deletedate
#         # required for trashinfo spec
#         # reference: https://github.com/andreafrancia/trash-cli/blob/master/trashcli/put/format_trash_info.py
#         filepath_urlencode="$(
#             IFS='/'
#             for i in $filepath; do
#                 [[ -z $i ]] && continue
#                 printf '/'
#                 urlencode "$i"
#             done
#         )"
#         printf -v deletedate "%(%Y-%m-%dT%H:%M:%S)T\n" -1

#         local ogfp="${filepath##*/}"
#         local target="$TRASHDIR/files/$ogfp"
#         local infotarget="${TRASHDIR}/info/$ogfp"
#         local potential_target
#         local potential_infotarget
#         local -i iter=0
#         while [[ -e "${infotarget-}" && -e "${target-}" ]]; do
#             iter=$((iter + 1))
#             potential_target="${target} ($iter)"
#             potential_infotarget="${infotarget} ($iter)"
#         done
#         infotarget="${potential_infotarget}.trashinfo"
#         target="$potential_target"

#         echo "$filepath $deletedate"

#         if mv "$filepath" "$target"; then
#             printf '%s\n' \
#                 '[Trash Info]' \
#                 "Path=$filepath_urlencode" \
#                 "DeletionDate=$deletedate" >"$infotarget"
#         else
#             echo "Error trashing file"
#         fi
#     else
#         echo "Skipping ---"
#         return
#     fi
# }

# I don't trust myself to implement the trash function properly in shell
_send_trash() {
    local filepath="${1:?Error, please select file to add to trash!}"
    local -i confirm=0
    [[ "${2-}" == --confirm ]] && confirm=1

    # xdg says if you don't have it in your $HOME, it can't be removed
    if [[ "${filepath:-}" != "${HOME:-}"* ]]; then
        echo "Error, could not trash file path '$filepath'!"
        _delete_forever "$filepath"
        return

    elif ((confirm)) || _prompt "Trash filepath '$filepath'?"; then
        "${trash_cmd[@]}" "$filepath"
        # if ((HAS_TRASH_CLI)); then
        #     echo "Trashing --- $filepath"
        #     trash -f "$filepath"
        # elif [[ -z ${DUMB_TRASH_DIR-} || ! -d ${DUMB_TRASH_DIR-} ]]; then
        #     _panic "FATAL ERROR!!! \$DUMB_TRASH_DIR has either been moved, or lost its value!" \
        #         'You should NEVER see this error. If you do, your computer is probably fucked'
        # else
        #     echo "Moving to fallback trash --- $filepath"
        #     mv -i "$filepath" "$DUMB_TRASH_DIR"
        # fi

    else
        echo "Skipping ---"
        return
    fi
}
declare -a trash_cmd=()
# declare -i HAS_TRASH_CLI=0
if command -v gio &>/dev/null; then
    trash_cmd=(gio trash)
elif command -v trash &>/dev/null; then
    # HAS_TRASH_CLI=1
    trash_cmd=(trash -f)
else
    DUMB_TRASH_DIR="${XDG_CACHE_HOME:=$HOME/.cache}/dumb-trash-dir"
    echo "Error, neither 'gio' nor 'trash-cli' were found! Falling back to dumb trash! ($DUMB_TRASH_DIR)"
    mkdir -p "$DUMB_TRASH_DIR" || exit
    _trash_cli_fallback() {
        mv -i "$1" "$DUMB_TRASH_DIR"
    }
    trash_cmd=(_trash_cli_fallback)
    # HAS_TRASH_CLI=0
fi
if command -v lscolors &>/dev/null; then
    __colorize() {
        lscolors "$@"
    }
else
    __colorize() {
        ls --color=always -Ad "$@"
    }
fi

# box-drawing characters, powerline characters, and some other nerd font icons, useful for output
#╭─┬─╮│    󰀄  󰕈
#├─┼─┤│   󰓎 󰘳  󰂽
#╰─┴─╯│   󰅟 󰘲 󰣇 󰣛
# 󰬛󰬏󰬌 󰬘󰬜󰬐󰬊󰬒 󰬉󰬙󰬖󰬞󰬕 󰬍󰬖󰬟 󰬑󰬜󰬔󰬗󰬌󰬋 󰬖󰬝󰬌󰬙 󰬛󰬏󰬌 󰬓󰬈󰬡󰬠 󰬋󰬖󰬎

# dependency check
declare -a faildeps=()
for i in rm mv realpath; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing dependencies:" "${faildeps[@]}"

# determine trash dir (needs to be here because I want to show the user in --help)

declare -a files=()
declare -a errors=()

_addfile() {
    # side affects: appends elements to 'files' and 'errors' arrays
    local file="${1:-}"
    [[ -z "${file:-}" ]] && return 0

    if [[ -L "${file:-}" ]]; then
        files+=("${file:-}")
    elif [[ -e "${file:-}" ]]; then
        files+=("$(realpath "$file")")
    else
        errors+=("${file:-}")
    fi
}

declare -i TRASH=32
declare -i STOP_ARGSPARSE=0

for i in "$@"; do
    if ((STOP_ARGSPARSE)); then
        _addfile "$i"
    else
        case "${i:-}" in
        --delete)
            TRASH=0
            ;;
        --trash)
            TRASH=1
            ;;
        --)
            STOP_ARGSPARSE=1
            ;;
        --help | -h | -help)
            echo "${0##*/} invalid arg: '$i'
Option flags apply to all files, and option args that come last override previous options
\`${0##*/} --delete file --trash file2\` will trash both files

Available options:

--delete   permanently delete the specified file
--trash    remove the file to trash (default)

--         all args received after this flag are instead parsed as files.
--help     show helptext
"
            exit 0
            ;;
        *)
            _addfile "$i"
            ;;
        esac
    fi
done
((${#errors[@]})) && _panic 'Error, could not find files:' "${errors[@]}"
((${#files[@]})) || _panic "Error, please select files to add to trash!"

if ((TRASH == 32)); then
    echo "case-insensitive options:"
    for i in "${files[@]}"; do
        unset ans
        printf '%s\n' \
            '' \
            "What do you want to do with this file?" \
            "$(__colorize "$i")" \
            ''
        printf '%s: %s\n' \
            T Trash \
            D Delete \
            S Skip \
            Q Quit
        read -r -p '[t/d/S/q] > ' ans
        case "${ans-}" in
        [Tt]) _send_trash "$i" --confirm ;;
        [Dd]) _delete_forever "$i" --confirm ;;
        [Ss] | '') echo "Skipping ---" && continue ;;
        [Qq]) echo "Quitting ---" && exit ;;
        esac
    done
elif ((TRASH)); then
    for i in "${files[@]}"; do
        _send_trash "$i"
    done
else
    for i in "${files[@]}"; do
        _delete_forever "$i"
    done
fi

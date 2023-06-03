#!/usr/bin/dash

set -eu

_select_session_fs () { #type: () -> %s(name)\t%s(file)\n
    local sesh
    local name
    for sesh in \
        /usr/share/wayland-sessions/* \
        /usr/local/share/wayland-sessions/* \
        /usr/share/xsessions/* \
        /usr/local/share/xsessions/*
    do
        [ "${sesh##*/}" = '*' ] && continue
        [ ! -f "$sesh" ] && continue
        name="$(grep -oP '^Name=\K.*$' "$sesh" || :)"
        [ -z "${name:-}" ] && continue
        printf '%s\t%s\n' "$name" "$sesh" # format-print the session name and file
    done # /bin is symlinked to /usr/bin in Fedora, and I want to sort -ur to show zsh and tmux first
    sed 's|^/bin|/usr/bin|g' /etc/shells | sort -ur | while read -r sesh; do
        [ "${sesh##*/}" = 'sh' ] && continue
        printf '%s\t%s\n' "TTY: ${sesh##*/} shell" "$sesh"
    done
}

_parse_desktopfile () { #type: %s(file.desktop) -> %s(cmd)
    local selection_file="${1:-}"
    echo "VLK_SESSION_NAME='$(grep -oP '^Name=\K[^ ]*' "$selection_file")'"
    echo "VLK_SESSION_EXEC='$(grep -oP '^Exec=\K.*$' "$selection_file")'"
}

select_session () { #type: () -> %s(cmd)
    local sessions
    sessions="$(_select_session_fs)"

    local max_size
    max_size="$(echo "$sessions" | cut -f 1 | wc -L)"
    #local IFS=$'\t\n'
    local oldifs="${IFS:-}"
    local IFS
    IFS="$(printf '\n\t')"
    local selection
    selection="$(printf "%-${max_size}s %s\n" $sessions | fzf --preview="$0 --preview {}")"
    IFS="$oldifs"

    local selection_file
    selection_file="${selection##* }"
    case "$selection_file" in
        *'xsessions'*)
            _parse_desktopfile "$selection_file"
            echo "VLK_SESSION_TYPE='xorg'"
            ;;
        *'wayland-sessions'*)
            _parse_desktopfile "$selection_file"
            echo "VLK_SESSION_TYPE='wayland'"
            ;;
        *)
            echo "unset VLK_SESSION_NAME"
            echo "VLK_SESSION_TYPE='shell'"
            echo "VLK_SESSION_EXEC='$selection_file'"
            ;;
    esac
}

case "${1:-}" in
    '--preview')
        if command -v bat >/dev/null; then
            previewcmd='bat'
        else
            previewcmd='cat'
        fi
        file="${2##* }"
        [ ! -f "${file:-}" ] && echo "Error, '${file:-}' is not a file!" && exit 1
        case "$(file -bL --mime-type "$file")" in
            'text/'*)
                $previewcmd "$file"
            ;;
            *)
                echo "File is not a text file"
            ;;
        esac
    ;;
    *)
        select_session
    ;;
esac

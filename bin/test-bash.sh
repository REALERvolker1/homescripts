#!/usr/bin/dash

# __vlkenv_tmppth=":${PATH}:"
# oldifs="$IFS"
# IFS=':'
# for i in \
#     $PATH \
#     '/usr/local/bin' \
#     '/var/lib/flatpak/exports/bin' \
#     "${PYTHONUSERBASE:-PYTHONUSERBASE}/bin" \
#     "${PNPM_HOME:-PNPM_HOME}" \
#     "${BUN_INSTALL:-BUN_INSTALL}/bin" \
#     "${GOPATH:-GOPATH}/bin" \
#     "${CARGO_HOME:-CARGO_HOME}/bin" \
#     "$HOME/.local/bin" \
#     "$HOME/bin"; do
#     case ":${__vlkenv_tmppth:-}:" in
#     *":${i}:"*) : ;;
#     *) [ -d "$i" ] && __vlkenv_tmppth="$i:$__vlkenv_tmppth" ;;
#     esac
# done
# IFS="$oldifs"
# echo "$__vlkenv_tmppth" | sed -E 's/:+/:/g;s/^:|:$//g'

PATHMUNGE_PATH="$PATH"

re() {
    tmppth="$(printf '%s:' "$PATHMUNGE_PATH" "$@")"
    outpath=
    oldifs="$IFS"
    IFS=':'
    for i in $tmppth; do
        i="$(realpath -e "$i" 2>/dev/null)"
        # [ ! -d "$i" ] && continue
        case ":${outpath:-}:" in
        *":${i}:"*) continue ;;
        *) [ -d "$i" ] && outpath="${outpath}:${i}" ;;
        esac
    done
    IFS="$oldifs"
    echo "$outpath"
}

re "$HOME/bin" \
    "$HOME/.local/bin" \
    "${CARGO_HOME:-CARGO_HOME}/bin" \
    "${GOPATH:-GOPATH}/bin" \
    "${BUN_INSTALL:-BUN_INSTALL}/bin" \
    "${PNPM_HOME:-PNPM_HOME}" \
    "${PYTHONUSERBASE:-PYTHONUSERBASE}/bin" \
    "$XDG_DATA_HOME/flatpak/exports/bin" \
    '/var/lib/flatpak/exports/bin' \
    '/usr/local/bin'

unset tmppth outpath oldifs i

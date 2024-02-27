#!/bin/bash
# shellcheck disable=SC1091,SC2039,SC2166
# WARNING -- only (barely) tested on Fedora. Tread carefully!

# C cache
if [ -d /usr/lib64/ccache ]; then
    case ":${PATH:-}:" in
    *:/usr/lib64/ccache:*) ;;
    *) PATH="/usr/lib64/ccache${PATH:+:$PATH}" ;;
    esac
fi

if [ -n "${CCACHE_DIR:-}" ] && [ ! -w "$CCACHE_DIR" ]; then
    unset CCACHE_DIR
    unset CCACHE_UMASK
elif [ "${EUID:-}" != 0 ] && [ -w /var/cache/ccache ] && [ -d /var/cache/ccache ]; then
    export CCACHE_DIR=/var/cache/ccache
    export CCACHE_UMASK=002
    unset CCACHE_HARDLINK
fi

[ -z "${DEBUGINFOD_URLS:-}" ] && export DEBUGINFOD_URLS='https://debuginfod.fedoraproject.org/'

# ls colors
#  && [ -z "${LS_COLORS:-}" ] && [ -z "${USER_LS_COLORS:-}" ]
if [ -z "${LS_COLORS:-}" ]; then
    for i in \
        "$XDG_CONFIG_HOME/dir_colors" \
        "$XDG_CONFIG_HOME/dircolors" \
        "$HOME/.dir_colors" \
        "$HOME/.dircolors" \
        '/etc/DIR_COLORS'; do
        for j in "$i.$TERM" "$i"; do
            if [ -r "$j" ]; then
                eval "$(dircolors --sh "$j" 2>/dev/null)"
                break
            fi
            [ -z "${LS_COLORS:-}" ] || break
        done
    done
fi
[ -z "${LS_COLORS:-}" ] && eval "$(dircolors)"
unset i j

# flatpak path
if command -v flatpak >/dev/null && ! expr "${XDG_DATA_DIRS:-}" : '.*flatpak.*' >/dev/null; then
    new_dirs=
    for i in \
        "${XDG_DATA_HOME:=$HOME/.local/share}/flatpak" \
        "$(
            unset G_MESSAGES_DEBUG
            GIO_USE_VFS=local flatpak --installations
        )"; do
        share_path="$i/exports/share"
        case ":$XDG_DATA_DIRS:" in
        *":$share_path:"* | *":$share_path/:"*) : ;;
        *) new_dirs=${new_dirs:+${new_dirs}:}$share_path ;;
            # *) new_dirs="$share_path:${new_dirs}" ;;
        esac
    done
    export XDG_DATA_DIRS="${new_dirs:+${new_dirs}:}${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    unset i new_dirs share_path
fi

# GNU Awk
gawkpath_default() {
    unset AWKPATH
    export AWKPATH="$(gawk 'BEGIN {print ENVIRON["AWKPATH"]}')"
}
gawkpath_prepend() { [ -z "$AWKPATH" ] && export AWKPATH="$*:$(gawk 'BEGIN {print ENVIRON["AWKPATH"]}')"; }
gawkpath_append() { [ -z "$AWKPATH" ] && export AWKPATH="$(gawk 'BEGIN {print ENVIRON["AWKPATH"]}'):$*"; }
gawklibpath_default() {
    unset AWKLIBPATH
    export AWKLIBPATH="$(gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}')"
}
gawklibpath_prepend() { [ -z "${AWKLIBPATH:-}" ] && export AWKLIBPATH="$*:$(gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}')"; }
gawklibpath_append() { [ -z "${AWKLIBPATH:-}" ] && export AWKLIBPATH="$(gawk 'BEGIN {print ENVIRON["AWKLIBPATH"]}'):$*"; }

# Mozilla openh264
[ -z "${MOZ_GMP_PATH:-}" ] && export MOZ_GMP_PATH="/usr/lib64/mozilla/plugins/gmp-gmpopenh264/system-installed"

# KDE
[ -z "${KDEDIRS:-}" ] && export KDEDIRS="/usr"
## When/if using prelinking, avoids (some) use of kdeinit
[ -z "${KDE_IS_PRELINKED:-}" ] && grep -qs '^PRELINKING=yes' /etc/sysconfig/prelink && export KDE_IS_PRELINKED=1

# Localization
export LANG="en_US.UTF-8"

[ -z "$LESSOPEN" ] && [ -x /usr/bin/lesspipe.sh ] && export LESSOPEN="||/usr/bin/lesspipe.sh %s"

if [ -z "$EDITOR" ]; then
    for i in nvim vim micro vi nano; do
        command -v "$i" >/dev/null 2>&1 && export EDITOR="$i"
    done
fi

me="$(realpath "/proc/$$/exe")"
case "$me" in
*/ksh*)
    alias which='alias | /usr/bin/which --tty-only --read-alias --show-tilde --show-dot'
    ;;
*/zsh | */bash)
    alias which='( alias; declare -f; ) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot'
    ;;
esac

# [ "${me#*bash}" != "$me" ] && [ -r "${BDOTDIR:-$HOME/.config/bash}/.bashrc" ] && . "${BDOTDIR:-$HOME/.config/bash}/.bashrc"

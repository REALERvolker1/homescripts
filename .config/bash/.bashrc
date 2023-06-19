# .bashrc
# shellcheck shell=bash
[[ $- != *i* ]] && return
unset MAILCHECK
#. /etc/bashrc
. /home/vlk/bin/vlkenv

if [[ $- == *i* ]] && [ -z "$NO_BLE" ]; then
    if [[ "$TERM" == *'xterm'* ]] || [[ "$TERM" == *'256'* ]]; then
        case "$CURRENT_DISTRO" in
        'Arch')
            pacman -Qs blesh &>/dev/null && [ -f '/usr/share/blesh/ble.sh' ] && . /usr/share/blesh/ble.sh --noattach --rcfile "$BDOTDIR/blerc"
            ;;
        'Fedora')
            if [ -f "${BDOTDIR:-$HOME}/launch-ble.sh" ]; then
                . "${BDOTDIR:-$HOME}/launch-ble.sh"
            elif [ -f "$HOME/.local/src/ble.sh/out/ble.sh" ]; then
                . "$HOME/.local/src/ble.sh/out/ble.sh" --noattach --rcfile "$BDOTDIR/blerc"
            fi
            ;;
        esac
    fi
fi

. /home/vlk/bin/vlkrc

for i in "$BDOTDIR/rc.d/"*'.bash'; do
    . "$i"
done

printf '%s -%s' "${0##*/}" "$-" | figlet -f smslant -w "$COLUMNS" | lolcat

[ -z "${BLE_VERSION:-}" ] && : || ble-attach

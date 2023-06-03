# .bashrc
[[ $- != *i* ]] && return
unset MAILCHECK
. /etc/bashrc
. /home/vlk/bin/vlkenv

if [[ $- == *i* ]] && [ -z "$NO_BLE" ]; then
    if [[ "$TERM" == *'xterm'* ]] || [[ "$TERM" == *'256'* ]]  ; then
        . "$HOME/.local/src/ble.sh/out/ble.sh" --noattach --rcfile "$BDOTDIR/blerc"
    fi
fi

. /home/vlk/bin/vlkrc

for i in "$BDOTDIR/rc.d/"*'.bash'; do
    . "$i"
done

printf '%s -%s' "${0##*/}" "$-" | figlet -f smslant -w "$COLUMNS" | lolcat

#. <(starship init bash)

[ -z "${BLE_VERSION:-}" ] && : || ble-attach

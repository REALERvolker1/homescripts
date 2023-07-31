# shellcheck shell=dash
## shellcheck disable=SC2155
. '/home/vlk/bin/vlkenv'

case "$0" in
*'bash'*)
    unset MAILCHECK
    ;;
esac

case "$-" in
*'i'*)
    #[ "$TERM" = 'linux' ] && [ "$(tty)" = /dev/tty1 ] && ( Hyprland )
    loginctl list-sessions --no-pager
    . "${BDOTDIR:-$HOME}/.bashrc"
    ;;
*)
    echo "non-interactive $0"
    ;;
esac
#[ "$TERM" = 'linux' ] && expr "$-" : '.*i' >/dev/null && exec vlkdm-login-profile.sh

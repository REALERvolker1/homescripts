# shellcheck shell=dash
. '/home/vlk/bin/vlkenv'

loginctl list-sessions --no-pager

case "$-" in
    *'i'*)
        if [ "$TERM" = 'linux' ]; then
            exec vlkdm-login-profile.sh
        fi
    ;;
    *)
        echo 'non-interactive'
    ;;
esac
#[ "$TERM" = 'linux' ] && expr "$-" : '.*i' >/dev/null && exec vlkdm-login-profile.sh

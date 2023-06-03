# shellcheck shell=dash
. '/home/vlk/bin/vlkenv'
loginctl list-sessions --no-pager
[ "$TERM" = 'linux' ] && expr "$-" : '.*i' >/dev/null && exec vlkdm-login-profile.sh

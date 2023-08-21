# shellcheck shell=dash
. '/home/vlk/bin/vlkenv'

if expr "$-" : '.*i' >/dev/null; then
    loginctl list-sessions --no-pager
    expr "$0" : '.*bash' >/dev/null && . "${BDOTDIR:-$HOME}/.bashrc"
fi
export PROFILESOURCED=true

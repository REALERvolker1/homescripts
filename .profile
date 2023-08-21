# shellcheck shell=dash
. /home/vlk/bin/vlkenv

if expr "$-" : '.*i' >/dev/null; then
    loginctl list-sessions --no-pager
    if expr "$0" : '.*bash' >/dev/null; then
        . "${BDOTDIR:-$HOME}/.bashrc"
    fi
fi

export PROFILESOURCED=true

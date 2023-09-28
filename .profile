# shellcheck shell=dash
. "$HOME/bin/vlkenv"
expr "$-" : '.*i' >/dev/null && {
    loginctl list-sessions --no-pager
    expr "$0" : '.*bash' >/dev/null 2>&1 && . "${BDOTDIR:-$HOME}/.bashrc"
}

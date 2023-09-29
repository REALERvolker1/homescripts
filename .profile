# shellcheck shell=dash
. "$HOME/bin/vlkenv"
expr "$-" : '.*i' >/dev/null && {
    loginctl list-sessions --no-pager
    case "$0" in
        *bash)
            rcfile="${BDOTDIR:-$HOME}/.bashrc"
            ;;
#        *zsh)
#            rcfile="${ZDOTDIR:-$HOME}/.zshrc"
#            ;;
        *dash)
            rcfile="$XDG_CONFIG_HOME/shell/dashrc"
            ;;
    esac
    PROFILESOURCED=true
    [ -f "$rcfile" ] && . "$rcfile"
    unset rcfile
    #expr "$0" : '.*bash' >/dev/null 2>&1 && . "${BDOTDIR:-$HOME}/.bashrc"
}

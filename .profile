# shellcheck shell=dash
#[ "${TERM:-}" = linux ] || export LC_ALL='en_US.UTF-8'
[ "${LANG:-C}" = 'C' ] && export LANG='en_US.UTF-8'
. "$HOME/bin/vlkenv"

# tab_character='	'
# expr "$-" : '.*i' >/dev/null
[ "${-#*i}" != "$-" ] && {
    [ "${HOSTNAME:=$(hostname)}" = "${CURRENT_HOSTNAME:-n}" ] && loginctl list-sessions --no-pager
    case "$0" in
    *bash)
        rcfile="${BDOTDIR:-$HOME}/.bashrc"
        ;;
    *dash)
        rcfile="$XDG_CONFIG_HOME/shell/dashrc"
        ;;
    esac
    [ -f "$rcfile" ] && . "$rcfile"
    unset rcfile
    PROFILESOURCED=true
    #expr "$0" : '.*bash' >/dev/null 2>&1 && . "${BDOTDIR:-$HOME}/.bashrc"
}

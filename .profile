# shellcheck shell=dash
. "${HOME:-~}/bin/vlkenv"

# tab_character='	'
# expr "$-" : '.*i' >/dev/null

if [ "${-#*i}" != "$-" ]; then
    [ "${HOSTNAME:=$(hostname)}" = "${CURRENT_HOSTNAME:-n}" ] && loginctl list-sessions --no-pager
    case "$0" in
    *bash)
        rcfile="${BDOTDIR:-$HOME}/.bashrc"
        ;;
    *dash)
        rcfile="$XDG_CONFIG_HOME/shell/dashrc"
        ;;
        #*zsh)
        #    rcfile="${ZDOTDIR:=$XDG_CONFIG_HOME/zsh}/.zshrc"
        #    ;;
    esac
    [ -f "$rcfile" ] && . "$rcfile"
    unset rcfile
    #expr "$0" : '.*bash' >/dev/null 2>&1 && . "${BDOTDIR:-$HOME}/.bashrc"
#else
#    eval $(set-cursor-theme.sh --shell-eval)
fi
eval $(set-cursor-theme.sh --shell-eval)
PROFILESOURCED=true

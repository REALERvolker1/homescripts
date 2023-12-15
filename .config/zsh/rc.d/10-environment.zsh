for i in \
    zsh="$ZDOTDIR" \
    bin="$HOME/bin" \
    code="$HOME/code" \
    pics="$HOME/Pictures" \
    var="$HOME/.var/app" \
    dots="$HOMESCRIPTS" \
    loc="$HOME/.local" \
    data="$XDG_DATA_HOME" \
    cache="$XDG_CACHE_HOME" \
    cfg="$XDG_CONFIG_HOME" \
    run="$XDG_RUNTIME_DIR" \
    rnd="$HOME/random" \
    i3="$XDG_CONFIG_HOME/i3" \
    sway="$XDG_CONFIG_HOME/sway" \
    hypr="$XDG_CONFIG_HOME/hypr" \
    steam="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
    hash -d $i
done
fpath=("$ZDOTDIR/site-functions" $fpath)
export -U PATH path FPATH fpath
export -U XDG_DATA_DIRS
export -U chpwd_functions
export -U precmd_functions
typeset -U module_path

chpwd_functions+=('__cd_ls')
module_path+=("$ZDOTDIR/modules")

# prevent all those pacman commands from showing up in my fedora machine history
[[ -z ${DISTROBOX_ENTER_PATH-} ]] && HISTFILE="$XDG_STATE_HOME/zshist"
SAVEHIST=50000
HISTSIZE=60000
READNULLCMD="${PAGER:-less}"

PROMPT=$'%k%f\n%B %F{14}%~%f %(0?.%F{10}%#.%F{9}%? %#) %b%f'
RPROMPT=
ZLE_RPROMPT_INDENT=0
PROMPT_EOL_MARK=${PROMPT_EOL_MARK-}
TMPPREFIX="$XDG_RUNTIME_DIR/zsh"

KEYBOARD_HACK='\'

export ZPLUGIN_DIR="$XDG_DATA_HOME/zsh-plugins"


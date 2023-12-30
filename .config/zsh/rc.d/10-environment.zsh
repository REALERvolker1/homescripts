foreach k v (
    zsh ${ZDOTDIR:-~}
    data $XDG_DATA_HOME
    state $XDG_STATE_HOME
    cache $XDG_CACHE_HOME
    cfg $XDG_CONFIG_HOME
    run $XDG_RUNTIME_DIR
    bin ~/bin
    code ~/code
    pics ~/Pictures
    var ~/.var/app
    dots ${HOMESCRIPTS:=~/homescripts}
    loc ~/.local
    rnd ~/random
    test ~/random/test
    rs $XDG_CONFIG_HOME/rustcfg
    i3 $XDG_CONFIG_HOME/i3
    sway $XDG_CONFIG_HOME/sway
    hypr $XDG_CONFIG_HOME/hypr
    nix $VLK_NIX_HOME
    steam ~/.var/app/com.valvesoftware.Steam/.local/share/Steam
) {
    [[ -d $v ]] && hash -d $k=$v
}

chpwd_functions+=('__cd_ls')
module_path+=("$ZDOTDIR/modules")

# prevent all those pacman commands from showing up in my fedora machine history
[[ -z ${DISTROBOX_ENTER_PATH-} ]] && HISTFILE="$XDG_STATE_HOME/zshist"
SAVEHIST=50000
HISTSIZE=60000
READNULLCMD=$PAGER

PROMPT=$'%k%f\n%B %F{14}%~%f %(0?.%F{10}%#.%F{9}%? %#) %b%f'
unset RPROMPT
ZLE_RPROMPT_INDENT=0
PROMPT_EOL_MARK=${PROMPT_EOL_MARK:-}
TMPPREFIX="$XDG_RUNTIME_DIR/zsh"

KEYBOARD_HACK='\'

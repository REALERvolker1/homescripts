# zsh hashed directory aliases
# running `cd ~zsh` will take me to ~/.config/zsh
foreach k v (
    zsh ${ZDOTDIR:-~}
    data $XDG_DATA_HOME
    state $XDG_STATE_HOME
    cache $XDG_CACHE_HOME
    cfg $XDG_CONFIG_HOME
    run $XDG_RUNTIME_DIR
    bin ~/bin
    code ~/code
    src ~/src
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
    steam ~/.var/app/com.valvesoftware.Steam/.local/share/Steam
) {
    [[ -d $v ]] && hash -d $k=$v
}
# nix $VLK_NIX_HOME

# run ls on cd (referencing a function I will autoload later in shell init)
chpwd_functions+=('__cd_ls')

# prevent all those pacman commands from showing up in my fedora machine history
[[ -z ${DISTROBOX_ENTER_PATH-} ]] && HISTFILE="$XDG_STATE_HOME/zshist"

# length of my history
SAVEHIST=50000
HISTSIZE=60000

# run `</path/to/file` in the interactive terminal
READNULLCMD=$PAGER  

# A default fallback prompt to use if my regular prompt script is incompatible with this term
PROMPT=$'%k%f\n%B %F{14}%~%f %(0?.%F{10}%#.%F{9}%? %#) %b%f'

# I don't want a right prompt unless I really need it
unset RPROMPT

# remove the random space at the right of a rightprompt
ZLE_RPROMPT_INDENT=0

# use the EOL mark from the env, or explicitly none.
# This prevents the default EOL of '%' from being appended to output that does not end with a newline.
PROMPT_EOL_MARK=${PROMPT_EOL_MARK:-}

# The tmpfs to store zsh-specific temporary files and shared memory (functions, compiled scripts, etc.) in
TMPPREFIX="$XDG_RUNTIME_DIR/zsh"

# Prevent ZLE from refusing to run my commands if I accidentally type this at the end of the line
KEYBOARD_HACK='\'


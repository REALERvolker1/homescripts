#!/usr/bin/zsh
set -euo pipefail

foreach k v (
    zsh ${ZDOTDIR:=~/.config/zsh}
    data ${XDG_DATA_HOME:=~/.local/share}
    state ${XDG_STATE_HOME:=~/.local/state}
    cache ${XDG_CACHE_HOME:=~/.cache}
    cfg ${XDG_CONFIG_HOME:=~/.config}
    run ${XDG_RUNTIME_DIR:=~/.run}
    bin ~/bin
    code ~/code
    pics ~/Pictures
    var ~/.var/app
    dots ${HOMESCRIPTS:=~/homescripts}
    loc ~/.local
    rnd ~/random
    i3 $XDG_CONFIG_HOME/i3
    sway $XDG_CONFIG_HOME/sway
    hypr $XDG_CONFIG_HOME/hypr
    nix $VLK_NIX_HOME
    steam ~/.var/app/com.valvesoftware.Steam/.local/share/Steam
) {
    [[ -d $v ]] && hash -d $k=$v
}
hash -d

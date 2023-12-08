# keybinds for zsh

# Disable CTRL-s from freezing your terminal's output.
stty stop undef

bindkey -v
export KEYTIMEOUT=1

typeset -A keymap=(
    [Ca]="^A"
    [home]="^[[H"
    [end]="^[[F"
    [delete]="^[[3~"
    [backspace]="^H"
    [backspace_two]="^?"
    [Cright]="^[[1;5C"
    [Cleft]="^[[1;5D"
    [As]='^[s'
    [AshiftS]='^[S'
    [Cz]="^Z"
    [Cy]="^Y"
    [Ce]="^E"
)

bindkey "${keymap[home]}" beginning-of-line
bindkey "${keymap[end]}" end-of-line
bindkey "${keymap[delete]}" delete-char
bindkey "${keymap[Cright]}" forward-word
bindkey "${keymap[Cleft]}" backward-word
bindkey "${keymap[backspace]}" backward-delete-char
bindkey "${keymap[backspace_two]}" backward-delete-char
bindkey "${keymap[Cz]}" undo
bindkey "${keymap[Cy]}" redo

bindkey -M vicmd "${keymap[home]}" beginning-of-line
bindkey -M vicmd "${keymap[end]}" end-of-line
bindkey -M vicmd "${keymap[delete]}" delete-char
bindkey -M vicmd "${keymap[Cright]}" forward-word
bindkey -M vicmd "${keymap[Cleft]}" backward-word
bindkey -M vicmd "${keymap[backspace]}" backward-delete-char
bindkey -M vicmd "${keymap[backspace_two]}" backward-delete-char
bindkey -M vicmd "${keymap[Cz]}" undo
bindkey -M vicmd "${keymap[Cy]}" redo

autoload -U edit-command-line
zle -N edit-command-line
bindkey $keymap[Ce] edit-command-line

__vlk::zle::sudo_prefix() {
    [[ $BUFFER == [[:space:]]# ]] && zle .up-history
    LBUFFER="sudo $LBUFFER"
}

zle -N __vlk::zle::sudo_prefix
bindkey -M main "${keymap[AshiftS]}" __vlk::zle::sudo_prefix

bindkey -M main "${keymap[As]}" expand-cmd-path

__vlk::zle::multidot_replace() {
    local dots=$LBUFFER[-3,-1]
    if [[ $dots =~ "^[ //\"']?\.\.$" ]]; then
        LBUFFER=$LBUFFER[1,-3]'../.'
    fi
    zle self-insert
}

# __vlk-zle-replace-exclamation-points() {
#     local points=$LBUFFER[-2,-1]
#     if [[ $points =~ "^[ //\"']?\.\.$" ]]; then
# }
zle -N __vlk::zle::multidot_replace
bindkey "." __vlk::zle::multidot_replace

__vlk::zle::expand_alias() {
    zle _expand_alias
    zle self-insert
    zle backward-delete-char
}
zle -N __vlk::zle::expand_alias
bindkey -M main "${keymap[Ca]}" __vlk::zle::expand_alias

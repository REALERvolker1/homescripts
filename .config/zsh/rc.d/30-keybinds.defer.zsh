# keybinds for zsh

# Disable CTRL-s from freezing your terminal's output.
stty stop undef

bindkey -v
export KEYTIMEOUT=1

typeset -A keymap
keymap[Ca]="^A"
keymap[home]="^[[H"
keymap[end]="^[[F"
keymap[delete]="^[[3~"
keymap[backspace]="^H"
keymap[backspace_two]="^?"
keymap[Cright]="^[[1;5C"
keymap[Cleft]="^[[1;5D"
keymap[As]='^[s'
keymap[AshiftS]='^[S'
keymap[Cz]="^Z"
keymap[Cy]="^Y"

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

__zle_vlk_sudo_prefix() {
    [[ $BUFFER == [[:space:]]# ]] && zle .up-history
    LBUFFER="sudo $LBUFFER"
}

zle -N __zle_vlk_sudo_prefix
bindkey -M main "${keymap[AshiftS]}" __zle_vlk_sudo_prefix
bindkey -M main "${keymap[As]}" expand-cmd-path

__zle_vlk_replace_multiple_dots() {
    local dots=$LBUFFER[-3,-1]
    if [[ $dots =~ "^[ //\"']?\.\.$" ]]; then
        LBUFFER=$LBUFFER[1,-3]'../.'
    fi
    zle self-insert
}

zle -N __zle_vlk_replace_multiple_dots
bindkey "." __zle_vlk_replace_multiple_dots

__zle_vlk_expand_alias() {
    zle _expand_alias
    zle self-insert
    zle backward-delete-char
}
zle -N __zle_vlk_expand_alias
bindkey -M main "${keymap[Ca]}" __zle_vlk_expand_alias

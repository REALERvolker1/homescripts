# keybinds for zsh

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
for i in main vicmd; do
    bindkey -M $i $keymap[home] beginning-of-line
    bindkey -M $i $keymap[end] end-of-line
    bindkey -M $i $keymap[delete] delete-char
    bindkey -M $i $keymap[Cright] forward-word
    bindkey -M $i $keymap[Cleft] backward-word
    bindkey -M $i $keymap[backspace] backward-delete-char
    bindkey -M $i $keymap[backspace_two] backward-delete-char
    bindkey -M $i $keymap[Cz] undo
    bindkey -M $i $keymap[Cy] redo
done

autoload -U edit-command-line
zle -N edit-command-line
bindkey $keymap[Ce] edit-command-line

bindkey -M main $keymap[As] expand-cmd-path

__vlk::zle::sudo_prefix() {
    [[ ${BUFFER-} == [[:space:]]# ]] && zle .up-history
    LBUFFER="sudo $LBUFFER"
}
zle -N __vlk::zle::sudo_prefix
bindkey -M main $keymap[AshiftS] __vlk::zle::sudo_prefix

# replace ... with ../..
__vlk::zle::multidot_replace() {
    local dots=$LBUFFER[-3,-1]
    [[ ${dots-} =~ "^[ //\"']?\.\.$" ]] && LBUFFER=$LBUFFER[1,-3]'../.'
    zle self-insert
}
zle -N __vlk::zle::multidot_replace
bindkey -M main '.' __vlk::zle::multidot_replace

__vlk::zle::hlep() {
    [[ ${LBUFFER:=} =~ (\'|\") || $LBUFFER != *'-hle' ]] || LBUFFER="${LBUFFER:: -3}hel"
    zle self-insert
}
zle -N __vlk::zle::hlep
bindkey -M main 'p' __vlk::zle::hlep

__vlk::zle::expand_alias() {
    zle _expand_alias
    zle self-insert
    zle backward-delete-char
}

# Disable CTRL-s from freezing your terminal's output.
# Has no effect in my zshconfig because I use zsh-defer for this config file
stty stop undef

zle -N __vlk::zle::expand_alias
bindkey -M main $keymap[Ca] __vlk::zle::expand_alias


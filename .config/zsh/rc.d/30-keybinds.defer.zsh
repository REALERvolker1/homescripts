# keybinds for zsh

bindkey -v
export KEYTIMEOUT=1

__vlk::zle::new_tab() {
    case ${TERM-} in
        xterm-kitty)
            kitty @ launch --cwd=current --type=tab
            ;;
        *)
            print "Error, your terminal cannot automatically open new tabs!"
            ;;
    esac
}
zle -N __vlk::zle::new_tab

typeset -A keymap=(
    [Ca]="^A"
    [home]="^[[H"
    [Chome]="^[[1;5H"
    [end]="^[[F"
    [Cend]="^[[1;5F"
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
    [Ct]="^T"
)
for i in main vicmd; do
    bindkey -M $i $keymap[home] beginning-of-line
    bindkey -M $i $keymap[Chome] beginning-of-line
    bindkey -M $i $keymap[end] end-of-line
    bindkey -M $i $keymap[Cend] end-of-line
    bindkey -M $i $keymap[delete] delete-char
    bindkey -M $i $keymap[Cright] forward-word
    bindkey -M $i $keymap[Cleft] backward-word
    bindkey -M $i $keymap[backspace] backward-delete-char
    bindkey -M $i $keymap[backspace_two] backward-delete-char
    bindkey -M $i $keymap[Cz] undo
    bindkey -M $i $keymap[Cy] redo
    bindkey -M $i $keymap[Ct] __vlk::zle::new_tab
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

# a little more than just aliases
__vlk::zle::hlep() {
    [[ ${LBUFFER:=} =~ (\'|\") || $LBUFFER != *'-hle' ]] || LBUFFER="${LBUFFER:: -3}hel"
    zle self-insert
}
zle -N __vlk::zle::hlep
bindkey -M main 'p' __vlk::zle::hlep

__vlk::zle::vim() {
    [[ ${LBUFFER-} == ivm || ${LBUFFER-} == vim ]] && LBUFFER="nvi"
    zle self-insert
}
zle -N __vlk::zle::vim
bindkey -M main 'm' __vlk::zle::vim

__vlk::zle::space() {
    if [[ -z ${LBUFFER// } ]]; then
        # disable prefix with space
        return
    # If there are just numbers in there, it is a shortcut for a loop
    elif [[ ${LBUFFER-} =~ ^[0-9]*$ ]]; then
        # only replace when it isn't an actual command
        if ! whence "$LBUFFER"; then
            LBUFFER="for ((i=0;i<$LBUFFER;i++));"
        fi
    fi
    zle self-insert
}
zle -N __vlk::zle::space
bindkey -M main ' ' __vlk::zle::space

# alias q=exit, but for sophisticated zsh intellectuals
__vlk::zle::quit() {
    if [[ -z ${LBUFFER-} ]]; then
        LBUFFER=exit
    else
        zle self-insert
    fi
}
zle -N __vlk::zle::quit
bindkey -M main 'q' __vlk::zle::quit


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


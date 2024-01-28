# keybinds for zsh

bindkey -v
# if it can't finish a keybind command in 1 second of me typing a key, I probably didn't want it anyway
export KEYTIMEOUT=1

# kitty-only new tab
if [[ ${TERM-} == xterm-kitty ]]; then
    __vlk::zle::kitty_new_tab() {
        kitty @ launch --cwd=current --type=tab >/dev/null
    }
    zle -N __vlk::zle::kitty_new_tab
fi

typeset -A keymap=(
    [home]="^[[H"
    [ctrl_home]="^[[1;5H"
    [end]="^[[F"
    [ctrl_end]="^[[1;5F"

    [delete]="^[[3~"
    [shift_backspace_or_ctrl_h]="^H"
    [backspace]="^?"

    [ctrl_right]="^[[1;5C"
    [ctrl_left]="^[[1;5D"

    [alt_s]='^[s'
    [alt_shift_s]='^[S'

    [ctrl_z]="^Z"
    [ctrl_y]="^Y"

    [ctrl_a]="^A"
    [ctrl_e]="^E"
    [ctrl_t]="^T"
)
for i in main vicmd; do
    bindkey -M $i $keymap[home] beginning-of-line
    bindkey -M $i $keymap[ctrl_home] beginning-of-line
    bindkey -M $i $keymap[end] end-of-line
    bindkey -M $i $keymap[ctrl_end] end-of-line

    bindkey -M $i $keymap[delete] delete-char
    bindkey -M $i $keymap[shift_backspace_or_ctrl_h] backward-delete-char
    bindkey -M $i $keymap[backspace] backward-delete-char

    bindkey -M $i $keymap[ctrl_right] forward-word
    bindkey -M $i $keymap[ctrl_left] backward-word

    bindkey -M $i $keymap[ctrl_z] undo
    bindkey -M $i $keymap[ctrl_y] redo
    [[ ${TERM-} == xterm-kitty ]] && bindkey -M $i $keymap[Ct] __vlk::zle::kitty_new_tab
done

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey $keymap[ctrl_e] edit-command-line

bindkey -M main $keymap[alt_s] expand-cmd-path

__vlk::zle::sudo_prefix() {
    [[ ${BUFFER-} == [[:space:]]# ]] && zle .up-history
    LBUFFER="sudo $LBUFFER"
}
zle -N __vlk::zle::sudo_prefix
bindkey -M main $keymap[alt_shift_s] __vlk::zle::sudo_prefix

# replace ... with ../..
__vlk::zle::multidot_replace() {
    if [[ $LBUFFER[-1] == '~' ]]; then
        # correct ~./ to ~/.
        LBUFFER=$LBUFFER'/'
    else
        local dots=$LBUFFER[-3,-1]
        [[ ${dots-} =~ "^[ //\"']?\.\.$" ]] && LBUFFER=$LBUFFER[1,-3]'../.'
    fi
    zle self-insert
}
zle -N __vlk::zle::multidot_replace
bindkey -M main '.' __vlk::zle::multidot_replace

# don't you hate it when you run `command --hlep` and then it says "OpTiOn HlEp NoT fOuNd PlEaSe RuN 'command --help'?"
# It's so useless. You know I passed an invalid flag, just show me the help text! Don't just tell me to do it and then exit!
# Fucking morons...
__vlk::zle::hlep() {
    [[ ${LBUFFER:=} =~ (\'|\") || $LBUFFER != *'-hle' ]] || LBUFFER="${LBUFFER:: -3}hel"
    zle self-insert
}
zle -N __vlk::zle::hlep
bindkey -M main 'p' __vlk::zle::hlep

# expand aliases when I hit ctrl-A
__vlk::zle::expand_alias() {
    zle _expand_alias
    zle self-insert
    zle backward-delete-char
}
zle -N __vlk::zle::expand_alias
bindkey -M main $keymap[ctrl_a] __vlk::zle::expand_alias

# a bunch of stuff I might want to run when I hit spacebar
__vlk::zle::space() {
    if [[ -z ${LBUFFER// } ]]; then
        # disable prefix with space
        return
    elif ((${+expand_aliases[${LBUFFER// }]} && ! ${+commands[${LBUFFER// }]})); then
        # expand configured aliases. Please see 80-aliases.zsh or ~/bin/vlkrc to see how this works
        LBUFFER="${expand_aliases[${LBUFFER// }]}"
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
    # if [[ -z ${LBUFFER-} ]]; then
    if [[ ${LBUFFER-} == ':' || ${LBUFFER-} == ':w' ]]; then
        LBUFFER=
    fi
    zle self-insert
}
zle -N __vlk::zle::quit
bindkey -M main 'q' __vlk::zle::quit

# I forget where I found this or why it's useful,
# but from what I can see, it probably makes sure to unfuck some stty stuff
if ((${+terminfo[smkx]} && ${+terminfo[rmkx]})) {
    zle-line-init () {
        echoti smkx
    }
    zle-line-finish () {
        echoti rmkx
    }
}


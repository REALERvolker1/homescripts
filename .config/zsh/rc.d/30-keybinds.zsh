# keybinds for zsh

bindkey -v
export KEYTIMEOUT=1

typeset -A keymap
keymap[home]="^[[H"
keymap[end]="^[[F"
keymap[delete]="^[[3~"
keymap[backspace]="^H"
keymap[Cright]="^[[1;5C"
keymap[Cleft]="^[[1;5D"
keymap[Cz]="^Z"
keymap[Cy]="^Y"

bindkey "${keymap[home]}" beginning-of-line
bindkey "${keymap[end]}" end-of-line
bindkey "${keymap[delete]}" delete-char
bindkey "${keymap[Cright]}" forward-word
bindkey "${keymap[Cleft]}" backward-word
bindkey "${keymap[backspace]}" backward-delete-char
bindkey "${keymap[Cz]}" undo # CTRL+Z
bindkey "${keymap[Cy]}" redo # CTRL+Y

bindkey -M vicmd "${keymap[home]}" beginning-of-line
bindkey -M vicmd "${keymap[end]}" end-of-line
bindkey -M vicmd "${keymap[delete]}" delete-char
bindkey -M vicmd "${keymap[Cright]}" forward-word
bindkey -M vicmd "${keymap[Cleft]}" backward-word
bindkey -M vicmd "${keymap[backspace]}" backward-delete-char
bindkey -M vicmd "${keymap[Cz]}" undo # CTRL+Z
bindkey -M vicmd "${keymap[Cy]}" redo # CTRL+Y

# Alt-Shift-S: Prefix the current or previous command line with `sudo`.
() {
    bindkey '^[S' $1    # Bind Alt-Shift-S to the widget below.
    zle -N $1           # Create a widget that calls the function below.
    $1() {              # Create the function.
        # If the command line is empty or just whitespace, then first load the
        # previous line.
        [[ $BUFFER == [[:space:]]# ]] &&
                zle .up-history

        # $LBUFFER is the part of the command line that's left of the cursor. This
        # way, we preserve the cursor's position.
        LBUFFER="sudo $LBUFFER"
    }
} .sudo

replace_multiple_dots () {
    local dots=$LBUFFER[-3,-1]
    if [[ $dots =~ "^[ //\"']?\.\.$" ]]; then
        LBUFFER=$LBUFFER[1,-3]'../.'
    fi
    zle self-insert
}

zle -N replace_multiple_dots
bindkey "." replace_multiple_dots

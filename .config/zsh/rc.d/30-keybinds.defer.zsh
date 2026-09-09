# keybinds for zsh

bindkey -v
# Allow 100 ms for a multi-byte key sequence.
KEYTIMEOUT=10
zmodload zsh/terminfo

# kitty-only new tab
# if [[ ${TERM-} == xterm-kitty ]]; then
    # __vlk::zle::kitty_new_tab() {
        # kitty @ launch --cwd=current --type=tab >/dev/null
    # }
    # zle -N __vlk::zle::kitty_new_tab
# fi

typeset -Ar keymap=(
    [home]="${terminfo[khome]-}"
    [ctrl_home]="${terminfo[kHOM5]-}"
    [end]="${terminfo[kend]-}"
    [ctrl_end]="${terminfo[kEND5]-}"

    [delete]="${terminfo[kdch1]-}"
    [shift_backspace_or_ctrl_h]="^H"
    [backspace]="${terminfo[kbs]-}"

    [ctrl_right]="${terminfo[kRIT5]-}"
    [ctrl_left]="${terminfo[kLFT5]-}"

    [alt_s]='^[s'
    [alt_shift_s]='^[S'

    [ctrl_z]="^Z"
    [ctrl_y]="^Y"

    [ctrl_a]="^A"
    [ctrl_e]="^E"
    [ctrl_g]="^G"
    # [ctrl_t]="^T"
)
() {
    local map key widget
    local -A bindings=(
        [home]=beginning-of-line
        [ctrl_home]=beginning-of-line
        [end]=end-of-line
        [ctrl_end]=end-of-line
        [delete]=delete-char
        [shift_backspace_or_ctrl_h]=backward-delete-char
        [backspace]=backward-delete-char
        [ctrl_right]=forward-word
        [ctrl_left]=backward-word
        [ctrl_z]=undo
        [ctrl_y]=redo
    )
    for map in main vicmd; do
        for key widget in "${(@kv)bindings}"; do
            # Extended key capabilities are not available on every terminal.
            [[ -n ${keymap[$key]} ]] || continue
            bindkey -M "$map" "${keymap[$key]}" "$widget"
        done
    done
}

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey $keymap[ctrl_g] edit-command-line

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
        if ! \whence "$LBUFFER"; then
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

# Make it so I can tab-complete for homedirs without my plugins breaking everything
# expands `lns ~rnd/images ~data/backgrounds` to `lns /home/vlk/random/images /home/vlk/.local/share/backgrounds`
# THE ISSUE WAS FINALLY FIXED!!
# __vlk::zle::expand_nameddirs() {
#     # Only works if there is a tilde
#     if [[ ${LBUFFER:=} != *'~'* ]]; then
#         zle self-insert
#         return
#     fi
#
#     local buffer
#     buffer="${LBUFFER##*'~'}"
#
#     # Prevent lag from typing ~///////
#     if [[ -n $buffer ]]; then
#         # only do one lookup
#         buffer="${nameddirs[$buffer]}"
#         if [[ -n $buffer ]]; then
#             LBUFFER="${LBUFFER%'~'*}$buffer"
#         fi
#     fi
#
#     zle self-insert
# }
# zle -N __vlk::zle::expand_nameddirs
# bindkey -M main '/' __vlk::zle::expand_nameddirs

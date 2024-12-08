. ${ZDOTDIR:-~}/environ.zsh

((${+commands[set-cursor-theme.sh]})) && eval $(=set-cursor-theme.sh --shell-eval)

# I stopped using sddm because it has a bug where it never starts graphically
[[ ${TERM-} == linux && ${TTY-} == /dev/tty* ]] && () {
    # This is an anon function
    local -a choices=(
        '1: Hyprland' 
        '2: startx' 
        '3: tmux' 
        "4: Regular ${SHELL:-zsh}"
        "5: bash"
        '6: Hyprland under bash (mitigate zsh killbug)'
    )
    local chosen
    chosen=$(print -l $choices | fzf)
    echo ${chosen:=}

    case $chosen in
    1*)
        exec Hyprland
        ;;
    2*)
        exec startx
        ;;
    3*)
        exec tmux
        ;;
    5*)
        exec bash
        ;;
    6*)
        exec bash -c Hyprland
        ;;
    *)
        echo "Resuming shell session"
        ;;
    esac
}


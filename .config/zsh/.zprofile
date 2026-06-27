. ${ZDOTDIR:-~}/environ.zsh

((${+commands[set-cursor-theme.sh]})) && eval $(=set-cursor-theme.sh --shell-eval)

# I stopped using sddm because it has a bug where it never starts graphically
[[ ${TERM-} == linux && ${TTY-} == /dev/tty* ]] && () {
    # This is an anon function
    local -a choices=(
		'1: Hyprland (UWSM)'
        '2: startx'
        '3: tmux'
        "4: Regular ${SHELL:-zsh}"
        "5: bash"
		'6: Hyprland (direct exec, may break xdg-desktop-portal)'
    )
    local chosen
    chosen=$(print -l $choices | fzf)
    echo ${chosen:=}

    case $chosen in
    1*)
		if uwsm check may-start 0; then
			exec uwsm start -e -D Hyprland hyprland.desktop
		fi
		print -u2 'UWSM refused to start a graphical session'
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
        exec start-hyprland
        ;;
    *)
        echo "Resuming shell session"
        ;;
    esac
}


# settings.bash
shopt -s autocd checkwinsize histappend
unset MAILCHECK

export HISTFILE="$XDG_STATE_HOME/bash_history"
export HISTCONTROL=erasedups:ignoreboth

# I am too lazy to relearn how to not fuck up a PS1, tysm 'https://scriptim.github.io/bash-prompt-generator/'
export PS1='\[\e[0;31m\][\[\e[0;2;32m\]\s\[\e[0;2;31m\]] \[\e[0;95m\]$? \[\e[0;1;3;4;96m\]\w\[\e[0;1;92m\] \$ \[\e[0m\]'

# never mind I just stole one from TehBoss#4823 on discord, suck it nerd lmaooo
[[ "$ICON_TYPE" != 'fallback' ]] && PROMPT_COMMAND=__prompt_command 
__prompt_command() {
    local exit="$?"
    PS1=""

    local reset='\[\e[0m\]'
    local white='\[\e[97m\]'
    local blue='\[\e[38;5;25m\]'
    local bgblue='\[\e[48;5;25m\]'
    local gray='\[\e[38;5;238m\]'
    local bggray='\[\e[48;5;238m\]'
    local red='\[\e[38;5;124m\]'
    local bgred='\[\e[48;5;124m\]'

    # Add user
    PS1+="${white}${bgblue} \u${blue}"
    # Add dir code
    PS1+="${bggray}${white} \w${reset}${gray}"

    if [ $exit != 0 ]; then
        # Change end color
        #PS1+="${bgred}${white} \w${reset}${red}"
        # Add exit code
        PS1+="${bgred}${white} ${exit}${reset}${red}"
    else
        # Change end color
        #PS1+="${bggray}${white} \w${reset}${gray}"
        # Add end cap
        PS1+=""
    fi
    PS1+="${reset} "
}

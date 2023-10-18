#!/usr/bin/zsh
# a rewrite of my psa script, this time in zsh
emulate -LR zsh
set -euo pipefail
TAB=''
LN='
'
IFS='
	' # because $'\n\t' syntax is cringe
[[ ${LS_COLORS:-} == *:di=*:ln=*:ex=* ]] || eval $(dircolors -b | grep -v 'export')
typeset -A color=( [dir]="${${LS_COLORS#*:di=}%%:*}" [exe]="${${LS_COLORS#*:ex=}%%:*}" [lnk]="${${LS_COLORS#*:ln=}%%:*}" )
((${${(@)color}[(Ie)${LS_COLORS%%:*}]})) && color=( [dir]='34' [exe]='32' [lnk]='36' )

# this is so cursed lmao wtf
foreach i ($@) {
    echo "received arg '$i'"
}

pidstat='pidstat --human -lRtU -p'
export S_COLORS='always'

reset="$(tput sgr0)"
pidfmt="$(echo -e "\e[${color[lnk]}m")"
namefmt="$(echo -e "\e[${color[dir]}m")"
argsfirstfmt="$(echo -e "\e[${color[exe]}m")"
defunctfmt="$(echo -e '\e[1;31m')"
argsfmt="$(echo -e '\e[32m')"

oldifs="$IFS"
IFS=$'\n'
# for i in $(ps -eo $'%p\t%c\t' -o exe -o $'\t%a'); do
myproc="$(
    ps -eo $'%p\t%c\t' -o exe -o $'\t%a' | while read -r i; do
    i_pid="${${i%%	*}// /}"
    i_tmp="${i#*	}"
    i_name="${${i_tmp%%	*}// /}"
    i_tmp="${i_tmp#*	}"
    i_comm="${${i_tmp%%	*}// /}"
    i_args="${i_tmp#*	}"

    [[ $i_args == \[*\] ]] && continue # filter kernel procs

    args_first_word=${i_args%% *}

    # get actual command path
    if [[ $i_comm == $args_first_word ]]; then
        args_construct="$i_args"
    elif [[ $i_comm == '-' ]]; then
        if [[ $i_args == *'<defunct>' ]]; then
            args_construct="$i_args"
        else
            args_construct="($i_comm) $i_args"
        fi
    elif [[ $args_first_word != */* ]]; then
        args_construct="($args_first_word) $i_comm ${i_args#* }"
    else
        args_construct="($i_comm) $i_args"
    fi
    args_construct="${args_construct::$COLUMNS}"

    # highlighting
    if [[ $i_name == *'<defunct>' && $i_args == *'<defunct>' ]]; then
        pid_hlstring="${reset}${defunctfmt}${i_pid}$reset"
        name_hlstring="${reset}${defunctfmt}${i_name}$reset"
        args_hlstring="${reset}${defunctfmt}${args_construct}$reset"
    else
        # args_construct="${args_construct//(-)/}"
        pid_hlstring="${reset}${pidfmt}${i_pid}$reset"
        name_hlstring="${reset}${namefmt}${i_name}$reset"
        args_hlstring="${reset}${argsfirstfmt}${args_construct%% *}$reset ${argsfmt}${args_construct#* }$reset"
    fi
    display="$pid_hlstring	$name_hlstring	$args_hlstring"

    echo $display
done | fzf --ansi --preview-window='down,25%' --header-lines=1 --preview="$pidstat \$(echo {} | sed 's|\t.*||')"
)"

pid="${myproc%%	*}"
proctmp="${myproc#*	}"
psname="${proctmp%%	*}"
args="${proctmp#*	}"

printproc() { print -l "PID: $pid" "NAME: $psname" "ARGS: $args"; }

typeset -a actions=(
    "%F{12}Get statistics (pidstat)%f"
    "%F{13}Print process details (internal)%f"
    "%F{10}Get process tree (pstree)%f"
)
[[ "$(ps --no-headers -o user -p $pid)" == $USER ]] && actions+=("%F{9}Kill process (kill)%f")

action_header="
\e[1mChoose an action, or press CTRL + C to cancel\e[0m
"

echo -e $action_header

select action in ${(%)actions}; do
    case "${REPLY:-}" in
        1) sh -c "$pidstat $pid" ;;
        2) printproc ;;
        3) pstree -sp $pid ;;
        4)
            ((${+actions[4]})) || exit 21
            printproc
            sh -c "$pidstat $pid"
            echo -en "\e[0mAre you \e[1msure\e[0m you want to \e[1;91mkill\e[0m this process?\n[y/N] > \e[1m"
            until [[ -n ${ans:-} ]] { read ans; }
            if [[ $ans == 'y' ]]; then
                kill $pid
            else
                echo "Process was not killed."
            fi
        ;;
        *) echo "Error, invalid reply $REPLY" ;;
    esac
    echo -en $action_header
    echo -e "\e[2m(Press RETURN to see options again)\e[0m"
done


# proc_owner="$(ps -o user -p "$myprog")"

# echo $proc_owner

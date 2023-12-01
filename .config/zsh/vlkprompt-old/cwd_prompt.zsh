#!/usr/bin/zsh
# echo $LINES $COLUMNS
# print -P "%F{23}hello%f"

declare -A cwd_prompt_internal=(
    [MAX_LS_HEIGHT]=4
    [LS_PAD]=3
)

cwd_prompt_internal+=(
    [full_pad]="$((${cwd_prompt_internal[MAX_LS_HEIGHT]} + ${cwd_prompt_internal[LS_PAD]}))"
    [maxhp1]="$((${cwd_prompt_internal[MAX_LS_HEIGHT]} + 1))"
)


__vlk_get_ls_print() {
    [[ ${cwd_prompt_internal[full_pad]} -gt $LINES || -z $(print -l ./*(N)) ]] && return
    local -i restwidth=$((COLUMNS - 4))
    local oldifs="${IFS:-}"
    local IFS=$'\n'
    local -a ls_output=($(\ls -A --color=always --hide-control-chars --group-directories-first --width=$restwidth --format=horizontal | \head -n ${cwd_prompt_internal[maxhp1]}))
    local -a ls_output_clean=($(print -l "${(@)ls_output}" | \sed 's/[^m]*m//g'))

    local -i ls_output_height=${#ls_output}
    if ((ls_output_height > ${cwd_prompt_internal[MAX_LS_HEIGHT]})); then
        local tagline='[MORE]'
        ((ls_output_height--))
        ls_output=("${(@)ls_output[1, $ls_output_height]}")
        ls_output_clean=("${(@)ls_output_clean[1, $ls_output_height]}")
    fi
    local width_line="─${$(printf "%${restwidth}s" '')// /─}─"

    local -a ls_display=(
        "╭${width_line}╮"
        $(
            for ((i=1;i<=ls_output_height; i++)); do
                printf "│ %s%$((${#ls_output_clean[i]} - restwidth))s │\n" "${ls_output[i]}"
            done
        )
        "╰${${tagline:+${width_line::-${#tagline}}}:-$width_line}${tagline}╯"
    )
    ((ls_output_height += 2))
    cwd_prompt_internal[ls_output_height]=$ls_output_height
    cwd_prompt_internal[ls_display]="${(j:\n:)ls_display}"
}

__vlk_zle_ls_display() {
    echo -en '\e[6n'
    local IFS="$oldifs"
    local IFS='[;'
    local -i x
    local -i y
    read -d R -rs _ y x _
    IFS="$oldifs"
    if (((LINES - y) < ${cwd_prompt_internal[full_pad]})); then
        for ((i=0; i<(${cwd_prompt_internal[LS_PAD]} + ${cwd_prompt_internal[ls_output_height]}); i++)); do
            echo
        done
        echo -en "\e[${cwd_prompt_internal[full_pad]}A"
    fi

    echo -en "\e[s\e[$((LINES - ${cwd_prompt_internal[ls_output_height]} + 1));0H"
    echo -n "${cwd_prompt_internal[ls_display]}"
    echo -en "\e[${y};${x}H"
}

__vlk_get_ls_print
__vlk_zle_ls_display
# sleep 15


# chpwd_functions+=('__vlk_get_ls_print')

precmd_functions+=('__vlk_get_ls_print' '__vlk_zle_ls_display')

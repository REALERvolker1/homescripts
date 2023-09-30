#!/bin/bash
# vlk script to run ls but print it in a little window
# `lsd || ls` grid view completely shits itself usually so here we are
IFS=$'\n\t'
command -v lsd &>/dev/null || exit 1

stty="$(stty size)"
columns="${stty#* }"
rows="${stty% *}"

ls_nocolor="$(lsd --color=never)"
[[ -z "${ls_nocolor:-}" ]] && exit
ls_max_width="$(echo "$ls_nocolor" | wc -L)"
ls_color="$(lsd --color=always)"

column_count="$(($((columns - 2)) / ls_max_width))"
remainder="$((columns - $((ls_max_width * column_count))))"
side_remainder="$(printf '%*s\n' "$(($((remainder / 2)) - 1))" '')" # rounds down
side_remainder_extra_block="$((remainder % 2))"
right_str="${side_remainder}"
((side_remainder_extra_block == 1)) && right_str=" $right_str"
left_str="${side_remainder}"

declare -a stuff color_stuff output
for i in $ls_nocolor; do
    stuff+=("$(printf '%-*s\n' "$((ls_max_width + 2))" "$i" | sed "s/$i//g")")
done
for i in $ls_color; do
    color_stuff+=("${i}")
done
for i in "${!stuff[@]}"; do
    output+=("${color_stuff[$i]}${stuff[$i]}")
done
echo $remainder
declare -i count=0
for ((i = 0; i <= ${#output[@]}; i++)); do
    elem="${output[$i]}"
    [ -z "${elem// /}" ] && continue
    if ((count == 0)); then
        echo -n "${left_str}"
    fi
    count=$((count + 1))
    echo -en "${output[$i]}"
    if ((count == column_count)); then
        count=0
        echo "${right_str}"
    fi
done

# ls_count="$(echo "$ls_nocolor" | wc -l)"
# ls_color="$(lsd --color=always)"

# echo "$ls_color"

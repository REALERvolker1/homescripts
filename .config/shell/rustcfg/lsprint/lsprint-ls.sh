#!/usr/bin/bash

specified_dir="${1:-$PWD}"
stty="$(stty size)"
columns="${stty#* }"
rows="${stty% *}"

IFS=$'\n'
declare -a ls_color ls_nocolor ls
for i in $(ls -A --group-directories-first -C --color=always "$specified_dir"); do
    ls_color+=("$i")
done
for i in $(ls -A --group-directories-first -C --color=never "$specified_dir"); do
    ls_nocolor+=("$i")
done

lswidth="$(echo "${ls_nocolor[@]}" | wc -L)"
lsheight="$(echo "${ls_nocolor[@]}" | wc -l)"
for i in "${!ls_nocolor[@]}"; do
    elem="${ls_nocolor[$i]}"
    ls+=("$(printf '%-*s\n' "$lswidth" "$elem" | sed "s/$elem/${ls_color[$i]}/")")
done

printf '%s\n' "${ls[@]}"

#!/usr/bin/bash

diff_file_path="$XDG_CACHE_HOME/lsdiff"
diff_folder="$HOME"

command -v lsd &>/dev/null || exit 1

ls_opts="lsd --ignore-config -A --group-dirs first --color always --icon always '$diff_folder'"

([[ "$1" == '--update' ]] || [ ! -f "$diff_file_path" ]) && eval "$ls_opts" >"$diff_file_path"

diff <(eval "$ls_opts") "$diff_file_path" | while read -r line; do
    #[[ "${line::1}" == '<' ]] && printf '\e[0m\e[1;92m+\e[0m %s\n' "$(lsd -d "$diff_folder/${line:2}")"
    [[ "${line::1}" == '<' ]] && printf '\e[0m\e[1;92m+\e[0m %s\n' "${line:2}"
    [[ "${line::1}" == '>' ]] && printf '\e[0m\e[1;31m-\e[0m \e[1;91m%s\e[0m\n' "${line:2}"
done
true

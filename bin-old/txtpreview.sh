#!/usr/bin/bash
# set -euo pipefail

find_deps() {
    local i freak
    for i in \
        file \
        realpath \
        pandoc \
        exiftool \
        chafa \
        ffmpeg \
        stat \
        bat; do
        depcheck "$i" || freak=true
    done
    [[ -z "${freak:-}" ]] || exit 1
}

depcheck() {
    command -v "${1:-}" &>/dev/null && return 0
    echo -e "\e[1;31mError\e[0;1m, failed to find dependency '${1:-}'! ($$)\e[0m"
    return 1
}

view_img() {
    chafa --format='symbols' --symbols all --animate=off "${1:-}"
}

view_markdown() {
    [[ -t 0 ]] && return 1
    if command -v glow &>/dev/null; then
        glow "$@"
    else
        bat -l md "$@"
    fi
}

tmpimg="$XDG_RUNTIME_DIR/tmp.jpg"

find_deps
for i in "$@"; do
    if [[ ! -e "${i:-}" ]]; then
        echo "Error, file '${i:-}' does not exist!"
        continue
    fi
    i="$(realpath -e "$i")"
    ext="${i##*.}"
    filecmd="$(file -bLi "$i")"
    type="${filecmd%%;*}"

    echo "$i"

    case "$type" in
    *'/directory')
        ls --color=always --group-directories-first -A "$i"
        ;;
    'image/gif' | 'video/'*)
        ffmpeg -y -ss 0:00:00 -i "$i" -frames:v 1 -q:v 2 "$tmpimg" &>/dev/null
        view_img "$tmpimg"
        exiftool "$i"
        ;;
    'image/heic')
        exiftool "$i"
        ;;
    'image/'*)
        ffmpeg -y -i "$i" -q:v 2 "$tmpimg" &>/dev/null
        view_img "$tmpimg"
        exiftool "$i"
        ;;
    'audio/'*)
        exiftool "$i"
        ;;
    'application/pdf')
        view_img "$i"
        ;;
    *)
        if [[ ${filecmd-} == *ascii || ${filecmd-} == *utf-8 ]]; then
            case "${ext:-}" in
            doc)
                pandoc -f docx -t markdown "$i" | view_markdown
                ;;
            odt | docx | org | rtf | html | epub | latex | textile | csv)
                pandoc -f "$ext" -t markdown "$i" | view_markdown
                ;;
            md)
                bat "$i"
                ;;
            xls | xlsx | ods)
                if depcheck in2csv; then
                    in2csv "$i" | pandoc -f csv -t plain -
                else
                    echo -e "\e[1mNon-critical dependency 'in2csv' not found!\e[0m"
                    stat "$i"
                fi
                ;;
            *)
                view_markdown "$i"
                ;;
            esac
        else
            stat "$i"
        fi
        ;;
    esac
done

# 'application/doc' | 'application/ms-doc' | 'application/msword' | 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
#     pandoc -f docx -t markdown "$i" | glow
#     ;;

# ls --color=always -Ald "$i"
# ls --color=always --group-directories-first -A "$i"

# ffmpeg -y -ss 0:00:00 -i "$i" -frames:v 1 -q:v 2 "$XDG_RUNTIME_DIR/tmp.jpg"

# chafa --format='symbols' --symbols all --animate=off "$i"

# in2csv ./file_example_XLS_50.xls | pandoc -f csv -t plain -

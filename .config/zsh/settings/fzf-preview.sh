#!/bin/dash
# requires: python3-csvkit, lsd, figlet, chafa, perl-Image-ExifTool, odt2txt, pdf2svg from dnf, xsv from cargo

set -eu

err_function () {
    [ -n "${1:-}" ] && echo "${1:-}"
    figlet -- fzf-tab
    exit 1
}

if [ -e "${1:-}" ]; then
    path="${1:-}"
elif [ -e "$PWD/${1:-}" ]; then
    path="$PWD/${1:-}"
else
    err_function "${1:-}"
fi

mime="$(file -bL --mime-type "$path")"
width="$(echo "$(tput cols) / 2 - 8" | bc)"

case "$mime" in
    *'/directory')
        lsd -ld "$path"
        lsd "$path"
    ;;
    'image/'*)
        #timg -g40x60 "$path"
        #timg "-g${width}x1000" "$path"
        chafa "--size=${width}x6000" --format='symbols' "$path"
        exiftool "$path"
    ;;
    *'/vnd.openxmlformats-officedocument.spreadsheetml.sheet' | *'/vnd.ms-excel')
        in2csv "$path" | xsv table | bat -ltsv --color=always
    ;;
    'text/'*)
        bat --color=always --line-range :200 "$path"
    ;;
    *'/vnd.oasis.opendocument.text')
        odt2txt "$path"
    ;;
    *'/pdf')
        pdf2svg "$path" "$XDG_RUNTIME_DIR/pdf2svg-preview.svg"
        chafa "--size=${width}x6000" --format='symbols' "$XDG_RUNTIME_DIR/pdf2svg-preview.svg"
    ;;
    *)
        err_function "$path"
    ;;
esac


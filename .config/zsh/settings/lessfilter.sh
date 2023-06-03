#!/usr/bin/dash
# this is a example of .lessfilter, you can change it

mime="$(file -bL --mime-type "$1")"
category="${mime%%/*}"
kind="${mime##*/}"

if [ -d "$1" ]; then
    lsd "$1"
elif [ "$category" = image ]; then
    timg -g40x60 "$1"
    #chafa "$1"
    exiftool "$1"
elif [ "$kind" = vnd.openxmlformats-officedocument.spreadsheetml.sheet ] || \
    [ "$kind" = vnd.ms-excel ]; then
    in2csv "$1" | xsv table | bat -ltsv --color=always
elif [ "$category" = text ]; then
    bat --color=always "$1"
else
    lesspipe.sh "$1" | bat --color=always
fi
# lesspipe.sh don't use exa, bat and chafa, it use ls and exiftool. so we create a lessfilter.

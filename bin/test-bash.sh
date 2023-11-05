#!/usr/bin/zsh

if [[ "${(j.:.)${(O)commands[@]##*/}}" == *lolcat*fortune* ]]; then
    fortune -a -s | lolcat
fi

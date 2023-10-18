#!/usr/bin/zsh

[[ ! -f "$XDG_CACHE_HOME/lsdiff.zsh.cache" || ${1:-} == '--update' ]] && print -l "$HOME"/(.|)* >"$XDG_CACHE_HOME/lsdiff.zsh.cache"
typeset -a cache=(${(f@Q)$(<"$XDG_CACHE_HOME/lsdiff.zsh.cache")})
typeset -a current=("$HOME"/(.|)*)
[[ ${cache[*]} == ${current[*]} ]] && echo exit 0


oldifs="$IFS"
IFS=$'\n'
current_fmt=($(lsd --ignore-config -AL1 --icon=always --color=always ${current:|cache}))
IFS="$oldifs"

test_fmt=($(lsd --ignore-config -AL1 --icon=always --color=always ${current:|cache}))

print -l ${${current_fmt//$HOME\//}/#/[92m+[0m } ${${${cache:|current}##*/}/#/[91m-[0m }

print -l $test_fmt

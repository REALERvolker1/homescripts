#!/bin/bash

declare -A colors=(
    [text_l]=255
    [text_d]=233
    [sudo]=196
    [cwd]=33
    [cwd_lnk]=45
    [git]=141
    [vim]=120
    [err]=52
    [job]=172
    [time]=226
    [ps2]=93
)
declare -A colorfmt=(
    [sudo]="%K{${colors[sudo]}}%B%F{${colors[text_d]}}"
    [cwd]="%K{${colors[cwd]}}%B%F{${colors[text_l]}}"
    [cwd_lnk]="%K{${colors[cwd_lnk]}}%B%F{${colors[text_d]}}"
    [git]="%K{${colors[git]}}%B%F{${colors[text_d]}}"
    [vim]="%K{${colors[vim]}}%B%F{${colors[text_d]}}"
    [err]="%K{${colors[err]}}%B%F{${colors[text_l]}}"
    [job]="%K{${colors[job]}}%B%F{${colors[text_d]}}"
    [time]="%K{${colors[time]}}%B%F{${colors[text_d]}}"
    [ps2]="%K{${colors[ps2]}}%B%F{${colors[text_l]}}"
    [dir]="%K{\${__vlkprompt_internal_prop[dir_color]}}%B%F{\${__vlkprompt_internal_prop[begin_end_dir_text]}}"
)
declare -A endcolorfgfmt=(
    [sudo]="%b%F{${colors[sudo]}}"
    [cwd]="%b%F{${colors[cwd]}}"
    [cwd_lnk]="%b%F{${colors[cwd_lnk]}}"
    [git]="%b%F{${colors[git]}}"
    [vim]="%b%F{${colors[vim]}}"
    [err]="%b%F{${colors[err]}}"
    [job]="%b%F{${colors[job]}}"
    [time]="%b%F{${colors[time]}}"
    [ps2]="%b%F{${colors[ps2]}}"
    [dir]="%b%F{\${__vlkprompt_internal_prop[dir_color]}}"
)
declare -A endcolorbgfmt=(
    [sudo]="%b%K{${colors[sudo]}}"
    [cwd]="%b%K{${colors[cwd]}}"
    [cwd_lnk]="%b%K{${colors[cwd_lnk]}}"
    [git]="%b%K{${colors[git]}}"
    [vim]="%b%K{${colors[vim]}}"
    [err]="%b%K{${colors[err]}}"
    [job]="%b%K{${colors[job]}}"
    [time]="%b%K{${colors[time]}}"
    [ps2]="%b%K{${colors[ps2]}}"
    [dir]="%b%K{\${__vlkprompt_internal_prop[dir_color]}}"
)
declare -A icons=(
    [cwd_ro]=
    [cwd_rw]=
    [git]=󰊢
    [err]=󰅗
    [job]=󱜯
    [time]=󱑃
    [end]=
    [end_r]=
    [end_sudo]=' '
    [dir]="\${__vlkprompt_internal_prop[dir_icon]}"
)
declare -A set=(
    [sgr_full]='%k%f%b%u%s'
    [sgr]='%k%f%b'
    [short]=130
)

echo "\
%(0?..${colorfmt[err]}%(${set[short]}V..) %? ${endcolorfgfmt[err]})\
${colorfmt[dir]}"

# echo "%(1j.${icons[job]}.)"

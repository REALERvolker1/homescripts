#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

# for command not found handler
# pacman -Fl | grep -P "[^\s]+\s+(/|)(usr|)/(local/|)bin/${query}$"
# grep -P "[^\s]+\s+(/|)(usr|)/(local/|)bin/${query}$" "$XDG_RUNTIME_DIR/vlkprompt-command-not-found.cache"

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
    [distrobox]=95
    [host]=18
    [login]=57
    [conda]=40
    [venv]=220
    [ps2]=93
    [ps3]=89
)
declare -A tcolor=(
    [sudo]="${colors[text_d]}"
    [cwd]="${colors[text_l]}"
    [cwd_lnk]="${colors[text_d]}"
    [git]="${colors[text_d]}"
    [vim]="${colors[text_d]}"
    [err]="${colors[text_l]}"
    [job]="${colors[text_d]}"
    [time]="${colors[text_d]}"
    [distrobox]="${colors[text_l]}"
    [host]="${colors[text_l]}"
    [login]="${colors[text_l]}"
    [conda]="${colors[text_d]}"
    [venv]="${colors[text_d]}"
    [ps2]="${colors[text_l]}"
    [ps3]="${colors[text_l]}"
)

declare -A icons=(
    [cwd_ro]=
    [cwd_rw]=
    [git]=󰊢
    [err]=󰅗
    [job]=󱜯
    [time]=󱑃
    [distrobox]=󰆍
    [host]=󰟀
    [login]=󱌒
    [conda]=󱔎
    [venv]=󰌠
    [end]=
    [end_r]=
    [end_sudo]=' '
)

declare -A set=(
    [sgr_full]='%k%f%b%u%s'
    [sgr]='%k%f%b'
    [short]=130
)

endgen() {
    local prev_color next_color text_color
    # previous color, next color, text color of next block
    if [[ ${1:-} == '--index' ]]; then
        shift 1
        prev_color="${colors[$1]}"
        next_color="${colors[$2]}"
        text_color="${tcolor[$2]}"
    else
        prev_color="$1"
        next_color="$2"
        [[ -n ${3:-} ]] && text_color="$3"
    fi
    echo "${set[sgr]}%F{$prev_color}%K{$next_color}${icons[end]}${text_color:+%B%F{$text_color\}}"
}

contentgen() {
    echo "%(${set[short]}V.. ${icons[$1]}) ${2:+$2 }"
}

declare -A ends=(
    #
    [login_host]="$(endgen --index login host)"
    [login_conda]="$(endgen --index login conda)"
    [login_venv]="$(endgen --index login venv)"
    [login_time]="$(endgen --index login time)"
    [login_job]="$(endgen --index login job)"
    [login_err]="$(endgen --index login err)"
    [login_cwd]="$(endgen "${colors[login]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [host_conda]="$(endgen --index host conda)"
    [host_venv]="$(endgen --index host venv)"
    [host_time]="$(endgen --index host time)"
    [host_job]="$(endgen --index host job)"
    [host_err]="$(endgen --index host err)"
    [host_cwd]="$(endgen "${colors[host]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [distrobox_conda]="$(endgen --index distrobox conda)"
    [distrobox_venv]="$(endgen --index distrobox venv)"
    [distrobox_time]="$(endgen --index distrobox time)"
    [distrobox_job]="$(endgen --index distrobox job)"
    [distrobox_err]="$(endgen --index distrobox err)"
    [distrobox_cwd]="$(endgen "${colors[distrobox]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [conda_venv]="$(endgen --index conda venv)"
    [conda_time]="$(endgen --index conda time)"
    [conda_job]="$(endgen --index conda job)"
    [conda_err]="$(endgen --index conda err)"
    [conda_cwd]="$(endgen "${colors[conda]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [venv_time]="$(endgen --index venv time)"
    [venv_job]="$(endgen --index venv job)"
    [venv_err]="$(endgen --index venv err)"
    [venv_cwd]="$(endgen "${colors[venv]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [time_job]="$(endgen --index time job)"
    [time_err]="$(endgen --index time err)"
    [time_cwd]="$(endgen "${colors[time]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [job_err]="$(endgen --index job err)"
    [job_cwd]="$(endgen "${colors[job]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [err_cwd]="$(endgen "${colors[err]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    #
    [err_cwd]="$(endgen "${colors[err]}" "\${__vlkprompt_internal[dir_color]}" "\${__vlkprompt_internal[dir_text]}")"
    [cwd_sudo]="$(endgen "${colors[sudo]}" "\${__vlkprompt_internal[dir_color]}")"
)

declare -A contents=(
    [login]="%(${set[short]}V. ${icons[login]} .)"
    [host]="$(contentgen host "%(${set[short]}V.%m.%M)")"
)

for i in "${!ends[@]}"; do
    printf '%s = %s\n' "$i" "${ends[$i]}"
done
for i in "${!contents[@]}"; do
    printf '%s = "%s"\n' "$i" "${contents[$i]}"
done

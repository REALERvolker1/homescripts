#!/usr/bin/zsh
# vlk prompt generator
# set -x
dependency_check() {
    local -a missing
    local i retval
    for i in zsh git pip distrobox conda; do
        command -v "$i" >/dev/null || missing+=("$i")
    done
    if [[ -z ${missing[*]} ]]; then
        echo -e "[\e[0;1;33mInfo\e[0m] All dependencies satisfied :D" >&2
        retval=0
    else
        echo -e "[\e[0;1;31mWarning\e[0m] Missing dependencies:" >&2
        printf '\t\e[1m%s\e[0m\n' "${missing[@]}" >&2
        echo -e "\tThe prompt may not work as intended" >&2
        retval=1
    fi
    if [[ ${1:-} == '--exit' ]]; then
        echo -e "\tExiting..." >&2
        exit $retval
    fi
    return $retval
}

case "${1:-}" in
    '--generate') : ;;
    '--depcheck')
    dependency_check --exit
    ;;
    *)
    [[ ! -d ${ZDOTDIR:-} ]] && unset ZDOTDIR
    if command -v "${0##*/}"; then
        me="${0##*/}"
    else
        me="$0"
    fi
    potential_fp="${${ZDOTDIR:+$ZDOTDIR/rc.d/40-}:-$HOME/.}vlkprompt.zsh"
    declare -a invalid_args=(\'$^@\')
cat << EOF
Invalid args: ${(@)invalid_args}
$(tput bold)Valid args$(tput sgr0)

--generate   generate the vlkprompt config file
--depcheck   check for dependencies on the system

$(tput bold)Intended usage:$(tput sgr0)

Finding your missing dependencies
$(tput dim)$me --depcheck$(tput sgr0)

Generating your config
$(tput dim)$me --generate > '$potential_fp'$(tput sgr0)

In your zshrc:

$(tput dim)# .zshrc
# ...
. $potential_fp
# ...
# loading aliases, plugins, etc$(tput sgr0)

You can zcompile the output file to make it run faster
$(tput dim)zcompile '$potential_fp'$(tput sgr0)
EOF
    exit 1
    ;;
esac

# declare -A icon icons colors colorsbg colorsfg colorstx content set ends index
declare -A icon colors txtcolor set index

# settings
MIN_TIMER_TIME_MINUS_ONE=14

index[transient]=130

index[conda]=132
index[venv]=133
index[timer]=134
index[sudo]=135
index[writable]=136
index[git]=137
index[vim]=138

set[icon_cwd_ro]=
set[icon_cwd_rw]=

icon[cwd]="%(${index[writable]}V.${set[icon_cwd_rw]}.${set[icon_cwd_ro]})"
icon[git]=󰊢
icon[vim]=

icon[err]=󰅗
icon[job]=󱜯
icon[tim]=󱑃

icon[dbx]=󰆍
icon[hos]=󰟀
set[icon_log]="%(${index[transient]}V.. 󰌆 )"

icon[con]=󱔎
icon[vev]=󰌠

set[end]=
set[end_r]=
set[sud_end]=' '

txtcolor[l]=255
txtcolor[d]=232

colors[cwd]=33
colors[git]=141
colors[vim]=120

colors[err]=52
colors[job]=172
colors[tim]=226

colors[dbx]=95
colors[hos]=18
colors[log]=55

colors[con]=40
colors[vev]=220

colors[ps2]=93
colors[ps3]=89
colors[ps4_i]=100
colors[ps4_n]=101

colors[sud]=196

set[sgr_full]='%k%f%b%u%s'
set[sgr]='%k%f%b'
set[ansi]='8;5;'

# distrobox -- $CONTAINER_ID
# python venv -- ${VIRTUAL_ENV##*/}
# anaconda -- $CONDA_DEFAULT_ENV

# for i in

declare -A cbg cfg txc icn

eval "$(
    printf "cbg[%s]='%%K{%s}'\n" "${(@kv)colors}"
    printf "cfg[%s]='%%F{%s}'\n" "${(@kv)colors}"
    printf "txc[%s]='%%B%%F{%s}'\n" "${(@kv)txtcolor}"
    printf "icn[%s]='%%(${index[transient]}V.. %s)'\n" "${(@kv)icon}"
)"
declare -A content endfg endbg en

# content[rps1]="\\\${vcs_info_msg_0_}"
content[git_begin]="${set[sgr]}${cfg[git]}${set[end_r]}${set[sgr]}${cbg[git]}${txc[d]}"
content[git_end]="${set[sgr]}"

content[cwd]="${cbg[cwd]}${txc[l]}${icn[cwd]}"
content[cwd]="%(${index[git]}V.${cbg[git]}${txc[d]}${icn[git]}.${content[cwd]})"
content[cwd]="%(${index[vim]}V.${cbg[vim]}${txc[d]}${icn[vim]}.${content[cwd]})"
content[cwd]="${content[cwd]} %\$((COLUMNS / 2))<..<%~ "

endfg[cwd]="%(${index[vim]}V.${cfg[vim]}.%(${index[git]}V.${cfg[git]}.${cfg[cwd]}))"
endbg[cwd]="%(${index[vim]}V.${cbg[vim]}.%(${index[git]}V.${cbg[git]}.${cbg[cwd]}))"

set[sud_end_v2]="%(${index[sudo]}V.${cbg[sud]}${set[end]}%(${index[transient]}V.${set[sgr]}${cfg[sud]}${set[end]}. ${set[sgr]}${cfg[sud]}${set[sud_end]}).${set[end]})${set[sgr]}"
set[sud_end_notransient]="%(${index[sudo]}V.${cbg[sud]}${set[end]}${set[sgr]}${cfg[sud]}${set[end]}.${set[end]})${set[sgr]}"

content[end]="${set[sgr]}${endfg[cwd]}${set[sud_end_v2]}"

content[err]="%(0?..${cbg[err]}${txc[l]}${icn[err]} %? )"
# endfg[err]="%(0?.${endfg[cwd]}.${cfg[err]})"
endbg[err]="%(0?.${endbg[cwd]}.${cbg[err]})"
en[err]="%(0?..${set[sgr]}${endbg[cwd]}${cfg[err]}${set[end]}${set[sgr]})"

content[job]="%(1j.${cbg[job]}${txc[d]}${icn[job]} %j .)"
# endfg[job]="%(1j.${cfg[job]}.${endfg[err]})"
endbg[job]="%(1j.${cbg[job]}.${endbg[err]})"
en[job]="%(1j.${set[sgr]}${endbg[err]}${cfg[job]}${set[end]}${set[sgr]}.)"

content[tim]="%(${index[timer]}V.${cbg[tim]}${txc[d]}${icn[tim]} \\\${__vlkprompt_internal[timer_str]} .)"
# endfg[tim]="%(${index[timer]}V.${cfg[tim]}.${endfg[job]})"
endbg[tim]="%(${index[timer]}V.${cbg[tim]}.${endbg[job]})"
en[tim]="%(${index[timer]}V.${set[sgr]}${endbg[job]}${cfg[tim]}${set[end]}${set[sgr]}.)"

export VIRTUAL_ENV_DISABLE_PROMPT=1
content[vev]="%(${index[venv]}V.${cbg[vev]}${txc[d]}${icn[vev]} \\\${__vlkprompt_internal[venv_str]} .)"
# endfg[vev]="%(${index[venv]}V.${cfg[vev]}.${endfg[tim]})"
endbg[vev]="%(${index[venv]}V.${cbg[vev]}.${endbg[tim]})"
en[vev]="%(${index[venv]}V.${set[sgr]}${endbg[tim]}${cfg[vev]}${set[end]}${set[sgr]}.)"

content[con]="%(${index[conda]}V.${cbg[con]}${txc[d]}${icn[con]} \\\${__vlkprompt_internal[conda_str]} .)"
# endfg[con]="%(${index[conda]}V.${cfg[con]}.${endfg[vev]})"
endbg[con]="%(${index[conda]}V.${cbg[con]}.${endbg[vev]})"
en[con]="%(${index[conda]}V.${set[sgr]}${endbg[vev]}${cfg[con]}${set[end]}${set[sgr]}.)"

# These are conditionals computed at the start of the prompt

# if log
content[log]="${cbg[log]}${txc[l]}${set[icon_log]}"
# endfg[log]="${cfg[log]}"
endbg[log]="${cbg[log]}"
en[log]="${set[sgr]}${endbg[con]}${cfg[log]}${set[end]}${set[sgr]}"
# else
content[nolog]=''
# endfg[nolog]="${endfg[con]}"
endbg[nolog]="${endbg[con]}"
en[nolog]=''

# if in distrobox
content[dbx]="${cbg[dbx]}${txc[l]}${icn[dbx]} \${CONTAINER_ID} "
# endfg[dbx]="${cfg[dbx]}"
endbg[dbx]="${cbg[dbx]}"
en[dbx_log]="${set[sgr]}${endbg[log]}${cfg[dbx]}${set[end]}${set[sgr]}"
en[dbx_nolog]="${set[sgr]}${endbg[con]}${cfg[dbx]}${set[end]}${set[sgr]}"

# elif just non-default hostname
content[hos]="${cbg[hos]}${txc[l]}${icn[hos]} %(${index[transient]}V.%m.%M) "
# endfg[hos]="${cfg[hos]}"
endbg[hos]="${cbg[hos]}"
en[hos_log]="${set[sgr]}${endbg[log]}${cfg[hos]}${set[end]}${set[sgr]}"
en[hos_nolog]="${set[sgr]}${endbg[con]}${cfg[hos]}${set[end]}${set[sgr]}"
# else
content[nohos]=''
# endfg[nohos]="${endfg[log]}"
endbg[nohos]="${endbg[log]}"
en[nohos]=''
promptgendate="generated on $(date +'%D @ %r') by $USER using $0"
# "$(git rev-parse --show-toplevel 2>/dev/null)"
cat << EOF
[[ "\$-" == *i* && -z \$BASH_VERSION && \$TERM != linux ]] || {
    return 1
    exit 1
}

# vlkprompt, $promptgendate
# Having a hard time understanding this autogenerated script?
# https://github.com/REALERvolker1/homescripts/blob/main/bin/promptgen.sh

unsetopt single_line_zle

# important variables
export VIRTUAL_ENV_DISABLE_PROMPT=1 # needed for proper python venv string
declare -A __vlkprompt_internal=(
    [right_prompt]=''
    [log_content]=''
    [log_end_color]=''
    [host_content]=''
    [host_end]=''
    [prev_pwd]=''
    [pwd]=''
    [pwd_writable]=''
    [pwd_git]=''
    [old_time]=0
    [timer_str]=''
    [venv_str]=''
    [conda_str]=''
)

if [[ -n \$CONTAINER_ID || \$HOSTNAME != \$CURRENT_HOSTNAME || \$- =~ l ]]; then
    if [[ \$- =~ l ]]; then
        __vlkprompt_internal[log_content]="${content[log]}%(${index[transient]}V..${en[log]})"
        __vlkprompt_internal[log_end_color]="${endbg[log]}"
    else
        __vlkprompt_internal[log_content]=''
        __vlkprompt_internal[log_end_color]="${endbg[con]}"
    fi
    if [[ \$HOSTNAME != \$CURRENT_HOSTNAME ]]; then
        if [[ -n \$CONTAINER_ID ]]; then
            __vlkprompt_internal[host_content]="${content[dbx]}${en[dbx]}"
            __vlkprompt_internal[host_end]="%(${index[transient]}V..${set[sgr]}\${__vlkprompt_internal[log_end_color]}${cfg[dbx]}${set[end]}${set[sgr]})"
        else
            __vlkprompt_internal[host_content]="${content[hos]}${en[hos]}"
            __vlkprompt_internal[host_end]="%(${index[transient]}V..${set[sgr]}\${__vlkprompt_internal[log_end_color]}${cfg[hos]}${set[end]}${set[sgr]})"
        fi
    fi
fi

PROMPT="\
%(${index[transient]}V..${set[sgr_full]}
)\
\${__vlkprompt_internal[host_content]}\${__vlkprompt_internal[host_end]}\
\${__vlkprompt_internal[log_content]}\
${content[con]}%(${index[transient]}V..${en[con]})\
${content[vev]}%(${index[transient]}V..${en[vev]})\
${content[tim]}%(${index[transient]}V..${en[tim]})\
${content[job]}%(${index[transient]}V..${en[job]})\
${content[err]}%(${index[transient]}V..${en[err]})\
${content[cwd]}${content[end]} "

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' use-simple 'true'
zstyle ':vcs_info:git:*' formats ' %r ${icon[git]} '
# zstyle ':vcs_info:git:*' actionformats ' %r '

__vlkprompt_internal[right_prompt]="%(${index[git]}V.${content[git_begin]}.)\\\${vcs_info_msg_0_}"
RPROMPT="\${__vlkprompt_internal[right_prompt]}"

# TIMEFMT -- the prompt you see in 'time command --args'
# TIMEFMT="%J  %U user %S system %P cpu %*E total"
TIMEFMT="$(print -P "${cbg[tim]}%F{${txtcolor[d]}} ${icon[job]} Command: %B%%J ${set[sgr]}${cfg[tim]}${set[end]}${set[sgr]}
${cbg[cwd]}%F{${txtcolor[l]}} ${icon[tim]} Elapsed time: %B%%*E ${set[sgr]}${cfg[cwd]}${set[end]}${set[sgr]}
${cbg[hos]}%F{${txtcolor[l]}} ${icon[hos]} user CPU time: %B%%U%b, kernel CPU time: %B%%S%b (total: %B%%P%b) ${set[sgr]}${cfg[hos]}${set[end]}${set[sgr]}")"

SUDO_PROMPT='$(print -P "\
${cbg[err]}${txc[l]} SUDO ${set[sgr]}${cfg[err]}${cbg[sud]}${set[end]}\
${cbg[sud]}${txc[l]} Please enter your password ${set[sgr]}${cfg[sud]}${set[sud_end]}${set[sgr]}") '

PROMPT_EOL_MARK='$(print -P "${cbg[err]}${txc[l]} 󰌑 ${set[sgr]}${cfg[err]}${set[end]}${set[sgr]}")'

command_not_found_handler() {
    echo "\$(tput sgr0)$(print -P "${cbg[sud]}${txc[d]} ${icon[err]} ERROR ${set[sgr]}${cfg[sud]}${cbg[err]}${set[end]}\
%F{${txtcolor[l]}} Command '%B\\\${1:-}%b' not found! ${set[sgr]}${cfg[err]}${set[end]}${set[sgr]}")"
    return 127
}

__vlkprompt_precmd() {
    local -i timer=\$((SECONDS - \${__vlkprompt_internal[old_time]}))
    __vlkprompt_internal[timer_str]=''
    if ((timer > ${MIN_TIMER_TIME_MINUS_ONE})); then
        local leading_zero timedisp timedisp_sm
        if ((timer > 60)); then
            local -i hour=\$((timer / 3600))
            local -i min=\$(((timer % 3600) / 60))
            local -i sec=\$((timer % 60))
            if ((hour > 0)); then
                timedisp="\${timedisp}\${hour}h "
                timedisp_sm="\${timedisp_sm}\${hour}:"
                ((min < 10)) && leading_zero=0
            fi
            if ((min > 0)); then
                timedisp="\${timedisp}\${min}m "
                timedisp_sm="\${timedisp_sm}\${leading_zero:-}\${min}:"
                ((sec < 10)) && leading_zero=0
            fi
            if ((sec > 0)); then
                timedisp="\${timedisp}\${sec}s "
                timedisp_sm="\${timedisp_sm}\${leading_zero:-}\${sec}:"
            fi
            timedisp="\${timedisp%* }"
            timedisp_sm="\${timedisp_sm%*:}"
        else
            timedisp="\${timer}s"
            timedisp_sm="\${timer}"
        fi
        psvar[134]=1
        __vlkprompt_internal[timer_str]="%(${index[transient]}V.\${timedisp_sm}.\${timedisp})"
    fi

    if [[ \$PWD == \${__vlkprompt_internal[pwd]} ]]; then
        psvar[${index[writable]}]="\${__vlkprompt_internal[pwd_writable]}"
        psvar[${index[git]}]="\${__vlkprompt_internal[pwd_git]}"
    else
        vcs_info
        if [[ \$PWD == \${__vlkprompt_internal[prev_pwd]} ]]; then
            psvar[${index[git]}]=1
        # elif git status &>/dev/null; then
        elif [[ -n \$vcs_info_msg_0_ ]]; then
            __vlkprompt_internal[prev_pwd]="\$PWD"
            psvar[${index[git]}]=1
        elif [[ -w \$PWD ]]; then
            psvar[${index[writable]}]=1
        fi
        __vlkprompt_internal[pwd]="\$PWD"
        __vlkprompt_internal[pwd_git]="\${psvar[${index[git]}]}"
        __vlkprompt_internal[pwd_writable]="\${psvar[${index[writable]}]}"
    fi
    if [[ -n \${CONDA_DEFAULT_ENV:-} ]]; then
        psvar[${index[conda]}]=1
        __vlkprompt_internal[conda_str]="\${CONDA_DEFAULT_ENV}"
    fi
    if [[ -n \${VIRTUAL_ENV:-} ]]; then
        psvar[${index[venv]}]=1
        __vlkprompt_internal[venv_str]="\${VIRTUAL_ENV##*/}"
    fi
    [[ -n \$VIRTUAL_ENV ]] && psvar[${index[venv]}]=1
}

export -U precmd_functions
precmd_functions+=('__vlkprompt_precmd' )

if [[ -z \${DISTROBOX_ENTER_PATH:-} ]]; then
    __vlkprompt_sudo_cmd() {
        if sudo -vn &>/dev/null; then
            psvar[${index[sudo]}]=1
        else
            psvar[${index[sudo]}]=''
        fi
    }
    precmd_functions+=('__vlkprompt_sudo_cmd')
fi

# function zle-line-init zle-keymap-select
__vlkprompt-zle-keymap-select() {
    if [[ \$KEYMAP == vicmd ]]; then
        psvar[${index[vim]}]=1
    else
        psvar[${index[vim]}]=
    fi
    zle reset-prompt
}
zle -N zle-keymap-select __vlkprompt-zle-keymap-select


__vlkprompt-zle-line-init() {
    [[ \$CONTEXT == start ]] || return 0
    ((\${+zle_bracketed_paste})) && print -r -n - "\${zle_bracketed_paste[1]}"
    zle recursive-edit
    local -i ret=\$?
    ((\${+zle_bracketed_paste})) && print -r -n - "\${zle_bracketed_paste[2]}"
    if [[ \$ret == 0 && \$KEYS == \$'\4' ]]; then
        psvar[${index[transient]}]=1
        zle reset-prompt
        exit
    fi
    local has_sudo="\${psvar[${index[sudo]}]}"
    psvar[${index[transient]}]=1
    RPROMPT=
    zle reset-prompt
    psvar=()
    psvar[${index[sudo]}]="\$has_sudo"
    __vlkprompt_internal[old_time]=\$SECONDS
    __vlkprompt_internal[timer_str]=
    RPROMPT="\${__vlkprompt_internal[right_prompt]}"
    if ((ret)); then
        zle send-break
    else
        zle accept-line
    fi
    return ret
}

zle -N zle-line-init __vlkprompt-zle-line-init

return
EOF

zshenv="${ZDOTDIR:-$HOME}/.zshenv"

zshenv_content=''
[[ -f $zshenv ]] && zshenv_content="$(grep -v -e '# vlkprompt-zshenv,' -e 'PROMPT4=' -e '^\s*$' "$zshenv")"
echo "${zshenv_content:+$zshenv_content
}# vlkprompt-zshenv, $promptgendate
PROMPT2='${set[sgr_full]}${cbg[ps2]}${txc[l]} %_ ${set[sgr]}${cfg[ps2]}${set[sud_end_notransient]} '
PROMPT3='${set[sgr_full]}${cbg[ps3]}${txc[l]} %# ${set[sgr]}${cfg[ps3]}${set[sud_end_notransient]} '
PROMPT4='${set[sgr]}${cbg[ps4_i]}${txc[l]} %i ${set[sgr]}${cfg[ps4_i]}${cbg[ps4_n]}${set[end]}${cfg[ps4_n]}${txc[l]} %N ${set[sgr]}${cfg[ps4_n]}${set[end]}${set[sgr]} '" >"$zshenv"

if command -v conda &>/dev/null; then
    conda_file=
    conda_ps=
    for i in "${XDG_CONFIG_HOME:-$HOME/.config}/conda/.condarc" "$HOME/.condarc"; do
        if [[ -r $i ]]; then
            conda_file="$i"
            grep -q '^\s*changeps1:\s*false' "$i" && conda_ps='true'
        fi
    done

    if [[ -n ${conda_msg:-} ]]; then
        echo -e "[\e[0;1;31mWarning\e[0m] conda PS1 not properly configured!
\tAdd the following to '\e[1;32m${conda_file:-$i}\e[0m':

\tchangeps1: false
" >&2
    # else
    #     echo -e "[\e[0;1;33mInfo\e[0m] Your conda ps1 is configured correctly" >&2
    fi
# else
#     echo -e "[\e[0;1;33mInfo\e[0m] To use the anaconda prompt module, please install conda." >&2
fi
dependency_check

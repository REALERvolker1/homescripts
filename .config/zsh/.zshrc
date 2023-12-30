[[ -n ${ZSH_VERSION-} && -o i && -t 0 && -t 1 && -t 2 ]] || {
    echo "failed to load zshrc"
    return 1
    exit 1
}
unset ZSHRC_LOADED


# clear the screen, then reset all, including font.
print -n '[0m[H[2J''(B)0\017[?5l7[0;0r8'

# I want to eliminate system-defined aliases. Change this on whatever distro.
# It def helps to not have '{' aliased to 'rm -rf ~/* &>/dev/null &!'
#printf '%s => %s\n' "${(@kv)aliases}"
\builtin unalias "${(@k)aliases}" cd &>/dev/null
## This is helpful if you use nix and you really need global aliases for some reason
#\builtin unalias ${(@k)builtins} ${(@k)reswords} &>/dev/null
## Run to see if you need to unfunction anything
# for i in ${(@k)builtins} ${(@k)aliases} ${(@k)reswords}; (($+functions[$i])) && echo $i

. ${ZDOTDIR:-~}/environ.zsh

### shell session settings
# VLKPROMPT_SKIP=1
# VLKPLUG_SKIP=1
# VLKATUIN_SKIP=1
# VLKZSH_RECOMPILE=1

# make ctrl+S not freeze the terminal
stty stop undef

# I set and unset many options, so I don't get surprised by weird settings
setopt inc_append_history share_history \
    hist_ignore_all_dups hist_expire_dups_first \
    hist_reduce_blanks hist_no_store hist_ignore_space \
    hist_fcntl_lock extended_history \
    \
    auto_cd auto_pushd cdable_vars pushd_ignore_dups multios extended_glob glob_dots \
    \
    glob_complete complete_in_word complete_aliases \
    interactive_comments prompt_subst no_bg_nice correct rm_star_wait

unsetopt hist_no_functions all_export global_export mark_dirs null_glob \
    no_unset err_exit pipefail

# load zsh modules
#zmodload zsh/pcre

typeset -ig VLKZSH_SAFEMODE=0
if ((VLKZSH_SAFEMODE)) || [[ ${TERM-} == linux || ${TTY-} == /dev/tty* || ${COLORTERM-} != truecolor ]] {
    VLKZSH_SAFEMODE=1
    # make truecolors behave well in TTY
    zmodload zsh/nearcolor
}

# Idea: debug mode function. When run, it adds useful stuff like lines/cols
# and persistent exec time and whatever to my prompt

# Certain files like vlkrc and vlkenv from ~/bin are loaded along with other settings files

foreach i ("${ZDOTDIR:-~/.config/zsh}/rc.d"/*.zsh) {
    if [[ $i == *.defer.zsh ]] {
        zsh-defer . "$i"
    } else {
        . "$i"
    }
}

for i in "$ZDOTDIR/functions"/^*.zwc(.N)
    autoload $i
    # autoload -Uz $i

((${+VLKZSH_RECOMPILE})) && echo "Recompiling..." && recompile >/dev/null

#eval "$(zoxide init zsh)"
#alias c=z
alias cd=z

if ((COLUMNS > 55)) {
    dumbfetch
    fortune -a -s | lolcat
    [[ -z ${DISTROBOX_ENTER_PATH-} ]] && lsdiff
}
unset i
typeset -i ZSHRC_LOADED=1
:


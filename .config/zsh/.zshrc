[[ -n ${ZSH_VERSION-} && -o i ]] || {
    echo "failed to load zshrc"
    return 1
    exit 1
}
unset ZSHRC_LOADED

# use zsh emulation, don't do any weirdness with arrays and whatnot
emulate -LR zsh

# clear the screen, then reset all, including font.
print -n '[0m[H[2J''(B)0\017[?5l7[0;0r8'

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
    interactive_comments prompt_subst no_bg_nice bsd_echo correct

unsetopt sh_glob sh_file_expansion sh_option_letters sh_word_split \
    ksh_glob ksh_autoload ksh_glob ksh_option_print ksh_typeset \
    hist_no_functions all_export global_export mark_dirs null_glob \
    no_unset err_exit pipefail

# load zsh modules
zmodload zsh/pcre

typeset -ig VLKZSH_SAFEMODE=0
if [[ ${TERM-} == linux || ${TTY:=$(tty)} == /dev/tty* || ${COLORTERM-} != truecolor ]]; then
    VLKZSH_SAFEMODE=1
    # make truecolors behave well in TTY
    zmodload zsh/nearcolor
fi

if [[ $IFS != $' \t\n\C-@' ]] {
    declare IFS
    echo 'Resetting non-default IFS'
    IFS=$' \t\n\C-@'
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
# for i in "$ZDOTDIR/functions"/*.zwc(.N)
for i in "$ZDOTDIR/functions"/^*.zwc(.N)
    autoload -Uz $i

((${+VLKZSH_RECOMPILE})) && echo "Recompiling..." && recompile >/dev/null

#eval "$(zoxide init zsh)"
alias c=z
alias cd=z

if ((COLUMNS > 55)) {
    dumbfetch
    fortune -a -s | lolcat
    [[ -z ${DISTROBOX_ENTER_PATH-} ]] && lsdiff
}
unset i
typeset -i ZSHRC_LOADED=1
:


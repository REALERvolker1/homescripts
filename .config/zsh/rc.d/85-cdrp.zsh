# vim:foldmethod=marker:ft=zsh

# Some directories I CD into are ones I would have rather CD'd into the realpath of.
typeset -gUa cdrp_aliases

# Give it higher priority
chpwd_functions=(__vlk::zsh::cd_to_realpath $chpwd_functions)

cdrp_aliases=(
    "$HOME/kubejs"
    "$HOME/Music"
    "$XDG_DATA_HOME/PrismLauncher"
)

__vlk::zsh::cd_to_realpath() {
    # Thanks to https://gist.github.com/ClementNerma/1dd94cb0f1884b9c20d1ba0037bdcde2
    if (( $cdrp_aliases[(Ie)${PWD}] == 0)); then
        return
    fi

    local -a old_chpwd_functions
    old_chpwd_functions=( "${chpwd_functions[@]}" )
    chpwd_functions=()

    \builtin cd "${PWD:A}"

    chpwd_functions=( "${old_chpwd_functions[@]}" )

}

# __test_echo_path() {
#     echo "$PWD"
# }
# chpwd_functions+=(__test_echo_path)

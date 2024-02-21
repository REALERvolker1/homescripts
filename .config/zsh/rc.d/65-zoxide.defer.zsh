# =============================================================================
#
# Utility functions for zoxide.
#

# pwd based on the value of _ZO_RESOLVE_SYMLINKS.
function _zoxide::pwd() {
    \builtin pwd -L
}

# cd + custom logic based on the value of _ZO_ECHO.
function _zoxide::cd() {
    # shellcheck disable=SC2164
    \builtin cd -- "$@"
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
function _zoxide::hook() {
    # shellcheck disable=SC2312
    \command zoxide add -- "$(_zoxide::pwd)"
}

# Initialize hook.
# shellcheck disable=SC2154
if [[ ${precmd_functions[(Ie)_zoxide::hook]:-} -eq 0 ]] && [[ ${chpwd_functions[(Ie)_zoxide::hook]:-} -eq 0 ]]; then
    chpwd_functions+=(_zoxide::hook)
fi

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

_zoxide::z_prefix='z#'

# Jump to a directory using only keywords.
function _zoxide::z() {
    # shellcheck disable=SC2199
    if [[ "$#" -eq 0 ]]; then
        _zoxide::cd ~
    elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]$ ]]; }; then
        _zoxide::cd "$1"
    elif [[ "$@[-1]" == "${_zoxide::z_prefix}"?* ]]; then
        # shellcheck disable=SC2124
        \builtin local result="${@[-1]}"
        _zoxide::cd "${result:${#_zoxide::z_prefix}}"
    else
        \builtin local result
        # shellcheck disable=SC2312
        result="$(\command zoxide query --exclude "$(_zoxide::pwd)" -- "$@")" &&
            _zoxide::cd "${result}"
    fi
}

# Jump to a directory using interactive search.
function _zoxide::zi() {
    \builtin local result
    result="$(\command zoxide query --interactive -- "$@")" && _zoxide::cd "${result}"
}

# Completions.
if [[ -o zle ]]; then
    function _zoxide::z_complete() {
        # Only show completions when the cursor is at the end of the line.
        # shellcheck disable=SC2154
        [[ "${#words[@]}" -eq "${CURRENT}" ]] || return 0

        if [[ "${#words[@]}" -eq 2 ]]; then
            _files -/
        elif [[ "${words[-1]}" == '' ]] && [[ "${words[-2]}" != "${_zoxide::z_prefix}"?* ]]; then
            \builtin local result
            # shellcheck disable=SC2086,SC2312
            if result="$(\command zoxide query --exclude "$(_zoxide::pwd)" --interactive -- ${words[2,-1]})"; then
                result="${_zoxide::z_prefix}${result}"
                # shellcheck disable=SC2296
                compadd -Q "${(q-)result}"
            fi
            \builtin printf '\e[5n'
        fi
        return 0
    }

    \builtin bindkey '\e[0n' 'reset-prompt'
    [[ "${+functions[compdef]}" -ne 0 ]] && \compdef _zoxide::z_complete _zoxide::z
fi

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

\builtin alias z=_zoxide::z
\builtin alias zi=_zoxide::zi

# =============================================================================
#
# To initialize zoxide, add this to your configuration (usually ~/.zshrc):
#
# eval "$(zoxide init zsh)"



pub const INIT_PRECMD_SCRIPT: &str = "__vlkprompt_precmd () {
    export VLKPROMPT_ERR=\"$?\"
    export VLKPROMPT_JOBS=\"$(jobs | wc -l)\"
    export VLKPROMPT_SUDO=\"$(sudo -vn &>/dev/null && echo true)\"
    export VLKPROMPT_GIT=\"$(git status &>/dev/null && echo true)\"
    export VLKPROMPT_VIM=''
}";
pub const INIT_ZSH_SCRIPT: &str = "precmd_functions+=('__vlkprompt_precmd')
";

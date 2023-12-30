#!/usr/bin/env zsh
set -euo pipefail

_panic() {
    print -l "$@" >&2
    exit 1
}

typeset -a faildeps
for i in pkill pgrep cargo rm
    command -v $i &>/dev/null || faildeps+=($i)
((${#faildeps[@]})) && _panic "Missing dependencies" $faildeps

mydir=${0:A:h}
bin="$mydir/target/release/power-cli"

if [[ ! -x $bin ]] {
    builtin cd $mydir
    cargo build --release || _panic "Could not build binary '$bin'!"
    [[ -x $bin ]] && print "Successfully built $bin"
}

pgrep -f $bin &>/dev/null && _panic "Error, already running! Running: $bin"
[[ ! -f $POWERCLI_LOCKFILE ]] && : > $POWERCLI_LOCKFILE
trap "[[ -e '$POWERCLI_LOCKFILE' ]] && rm '$POWERCLI_LOCKFILE'" EXIT

SIGNAL='SIGRTMIN+8'

typeset -a result_command=($bin)

case ${1-} in
--term)
    result_command+=('--stdout')
    update_output() {
        print $line
    }
    ;;
--waybar)
    result_command+=('--waybar')
    update_output() {
        print $line >$POWERCLI_LOCKFILE
        pkill -$SIGNAL waybar
    }
    ;;
--waybar-stdout)
    result_command+=('--waybar')
    update_output() {
        print $line
    }
    ;;
*)
    _panic "Usage: $0 [--option]" \
        "--term    Print terminal output to stdout" \
        "--waybar  Update a custom waybar module, killing it with $SIGNAL to update it" \
        "--waybar-stdout  Print raw waybar output to stdout"
    ;;
esac

prevline=''

print "Starting power-cli daemon"

"${result_command[@]}" | while read -r line; do
    [[ $line == $prevline ]] && continue
    prevline=$line
    update_output $line
done

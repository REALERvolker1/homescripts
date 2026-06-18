#!/usr/bin/env zsh
# Minimal reproducer for the zsh-autocomplete async fd leak.
# The subprocess invocation is the process substitution passed to sysopen.

emulate -L zsh
setopt no_aliases pipefail

zmodload -F zsh/system b:sysopen || exit 1

integer fd_limit=${1:-64}
integer max_iters=${2:-200}

ulimit -n "$fd_limit" || exit 1

print -r -- "fd limit: $(ulimit -n)"
print -r -- 'broken pattern: sysopen -u fd <(subprocess), then [[ -t $fd ]] && close'
print -r -- 'expected: sysopen eventually fails because pipe fds are not ttys and never close'

integer i
for (( i = 1; i <= max_iters; ++i )); do
  fd=
  if ! sysopen -r -o cloexec -u fd <(
    print -r -- "subprocess output $i"
  ); then
    print -ru2 -- "FAILED at iteration $i; fd variable is ${fd:-unset}"
    print -ru2 -- 'This matches the plugin failure class: sysopen cannot open /proc/self/fd/N.'
    exit 1
  fi

  # Broken close guard from zsh-autocomplete 20f6c34:
  # process-substitution fds are pipes, not terminals, so this is false.
  [[ -t $fd ]] && exec {fd}<&-

  (( i % 10 == 0 )) && print -r -- "iteration $i: leaked fd $fd"
done

print -ru2 -- 'No failure; lower fd_limit or raise max_iters.'
exit 2

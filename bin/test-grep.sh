#!/usr/bin/zsh

typeset -A assoc=(
  'key1' 'value 1'
  'key2' 'value 2'
)

for i in "${(@k)assoc}"; do
    declare "assoc[$i]=hh${assoc[$i]}hh"
done

printf '%s=%s\n' "${(@kv)assoc}"

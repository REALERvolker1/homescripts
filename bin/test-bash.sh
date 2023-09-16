#!/usr/bin/zsh

typeset -A assoc=(
  'key1' 'value 1'
  'key2' 'value 2'
)

eval "$(printf 'declare "assoc[%s]=hh%shh"\n' "${(@kv)assoc}")"

printf '%s=%s\n' "${(@kv)assoc}"

for i in "${(@k)colorsbg}"; do
    declare ""
done
eval "$(printf "declare 'colorsbg[%s]=${set[o]}${set[bg_esc]}%s${set[end_esc]}${set[c]}'\n" "${(@kv)colorsbg}")"

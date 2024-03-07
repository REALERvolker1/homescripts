#!/usr/bin/zsh
set -euo pipefail

typeset -A desktop_entries

foreach desktop_entry (${(u)${~${(As.:.)${${XDG_DATA_DIRS//:}:+$XDG_DATA_DIRS}:-/usr/share:${XDG_DATA_HOME:=~/.local/share}}//%/\/applications/*.desktop(N-.:A)}}) {
    typeset -A entry=([Icon]='error' [Name]='UNDEFINED' [Exec]=false) # [File]="$desktop_entry"
    typeset ${${${(M)"${(@f)"$(<$desktop_entry)"}":#(Name|Exec|Icon)=*}/#/entry[}/=/]=}
    desktop_entries[$desktop_entry]="${(j: :)${(qkv@)entry}}"
    unset entry
}

foreach key (${(@k)desktop_entries}) {
    typeset -A entry=("${(Q@)${(z@)${desktop_entries[$key]}}}")
    printf '[%s] = %s\n' ${(kv)entry}
    unset entry
}


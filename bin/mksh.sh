#!/usr/bin/bash
set -euo pipefail

binpath="$HOME/bin"

_panic() {
    printf '%s\n' "$@"
    exit 1
}

file="${1:?Error, please specify a file!}"

if [[ $file == *'/'* ]]; then
    if [[ $file == '/'*'/' ]]; then
        _panic "Error, invalid absolute path for file! '$file'"
    elif [[ $file == '/'* ]]; then
        true
    elif [[ $file == *'/'* ]]; then
        _panic "Error, file cannot have slashes in its name! '$file'"
    fi
else
    file="$binpath/$file"
fi

[[ -e $file ]] && _panic "Error, file '$file' already exists!"

cat >"$file" <<EOF
#!/usr/bin/bash
# shellcheck shell=bash
# a script that does a thing.
set -euo pipefail
IFS=\$'\\n\\t'

# useful functions
_panic() {
    printf '[0m%s[0m\\n' "\$@" >&2
    exit 1
}

_strip_color() {
    # Strip all occurences of ansi color strings from input strings
    # uncomment matches to do stuff with the strings themselves
    local ansi_regex='\\[([0-9;]+)m'
    local i
    # local -a matches=()
    for i in "\$@"; do
        while [[ \$i =~ \$ansi_regex ]]; do
            # matches+=("\${BASH_REMATCH[1]}")
            i=\${i//\${BASH_REMATCH[0]}/}
        done
        echo "\$i"
    done
}

# box-drawing characters, powerline characters, and some other nerd font icons, useful for output
#╭─┬─╮│    󰀄  󰕈
#├─┼─┤│   󰓎 󰘳  󰂽
#╰─┴─╯│   󰅟 󰘲 󰣇 󰣛
# 󰬛󰬏󰬌 󰬘󰬜󰬐󰬊󰬒 󰬉󰬙󰬖󰬞󰬕 󰬍󰬖󰬟 󰬑󰬜󰬔󰬗󰬌󰬋 󰬖󰬝󰬌󰬙 󰬛󰬏󰬌 󰬓󰬈󰬡󰬠 󰬋󰬖󰬎

# dependency check
declare -a faildeps=()
for i in placeholder_dep{1,2}; do
    command -v "\$i" &>/dev/null || faildeps+=("\$i")
done
((\${#faildeps[@]})) && _panic "Error, missing dependencies:" "\${faildeps[@]}"

# argparse
declare -A config=(
    [bool]=0
    [str]=''
)
declare -a files=()

for i in "\$@"; do
    case "\${i:=}" in
    --bool)
        config[bool]=1
        ;;
    --no-bool)
        config[bool]=0
        ;;
    --str=)
        config[str]="\${i#*=}"
        ;;
    -*)
        cat <<BRUH
Error, invalid arg passed! '\$i'

Valid arguments include:
--bool        enable bool
--no-bool     disable bool
--str='text'  Set str value

[files]       All other args are passed as files

BRUH
        exit 2
        ;;
    *)
        files+=("\$i")
        ;;
    esac
done

EOF

chmod +x "$file"

for i in codium code "${VISUAL:-}" "${EDITOR:-}" echo; do
    command -v "$i" &>/dev/null && exec "$i" "$file"
done

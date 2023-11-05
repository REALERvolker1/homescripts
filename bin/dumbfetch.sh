#!/usr/bin/dash
# shellcheck disable=3028
box_color="[38;5;$(shuf -i 1-255 -n 1)m"

prop0="${SHLVL:-999}"
prop1="$(uptime -p | sed 's/^up // ; s/hour/hr/g ; s/minute/min/g')"
prop2="${TERM:-Undefined}"
prop3="$(df -h -l -t btrfs -t xfs -t ext4 --output=pcent | uniq | sed -z 's/\n/ /g ; s/  */ /g ; s/Use% //')"
if [ -n "${CONTAINER_ID:-}" ]; then
    prop4="${CONTAINER_ID:-}"
    prop4_label='󰏖 Distbx'
else
    prop4="$(nvidia-settings -v | grep -oP 'version\s\K[^\s]+')"
    prop4_label='󰾲 Nvidia'
fi
prop5="$(uname -r | grep -o '^[^-]*-[^.]*')"

len=0
for i in "$prop1" "$prop2" "$prop3" "$prop4" "$prop5"; do
    [ "${#i}" -gt "$len" ] && len="${#i}"
done
# could literally be done in zsh with a single simple expansion ${${(On)${(N)props%%*}}[1]}

# length_string="$(printf "%-${len}s\n" '' | sed 's/ /─/g')"
length_string="$(printf "%0.s─" $(seq 1 "$len"))"
# printf -v length_string "%0.s─" $(seq 1 "$len")

printf '%s\n' "${box_color}╭────────────────┬─────────────${length_string}╮[0m"
printf "${box_color}│[0m[92m%s${box_color}│[0m%s   [1m%-${len}s [0m${box_color}│[0m\n" \
    '        _ _     ' '[94m  SHLVL ' "$prop0" \
    ' __   _| | | __ ' '[95m 󰅐 Uptime' "$prop1" \
    ' \ \ / / | |/ / ' '[96m  Term  ' "$prop2" \
    '  \ V /| |   <  ' '[93m 󰋊 Disk  ' "$prop3" \
    '   \_/ |_|_|\_\ ' "[92m $prop4_label" "$prop4" \
    '                ' '[91m  Kernel' "$prop5"
printf '%s\n' "${box_color}╰────────────────┴─────────────${length_string}╯[0m"
# ┴

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
TAB=$'\t'

case "${1:-}" in
--fzf) declare -i IS_FZF_MODE=1 ;;
'' | --rofi) declare -i IS_FZF_MODE=0 ;;
*)
    printf '%s\n' \
        "Error, invalid arg: '${1:-}'" \
        'Available options:' \
        '--fzf   use fzf as a selector' \
        '--rofi  use rofi as a selector (default)'
    exit 1
    ;;
esac

if ((IS_FZF_MODE)) || [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
    roficmd=fzf
    declare -a rofi_args=('-0' '--ansi' '--height=10%')
    declare -a mesg_rofi_args=('--header')

    printcmd() {
        local oldifs="$IFS"
        local IFS=$'\n'
        printf '%s%s\e[0m\n' $(printf '%s\n' "$@" | tac)
        IFS="$oldifs"
    }

    # disable multi select
    [[ -n "${FZF_DEFAULT_OPTS:-}" ]] && export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS//--multi/}"

    declare -A gfx_icons=(
        [hybrid]='[32m'
        [integrated]='[34m'
        [compute]='[36m'
        [vfio]='[33m'
        [asusmuxdgpu]='[35m'
        [nvidianomodeset]='[32m'
        [undefined]='[31m'
    )
    declare -A power_icons=(
        [performance]='[31m'
        [balanced]='[33m'
        [quiet]='[32m'
        ['power-saver']='[32m'
        [undefined]='[31m'
    )
    declare -A od_icons=(
        [true]='[32m'
        [false]='[31m'
        [undefined]='[31m'
    )
else
    roficmd=rofi
    declare -a rofi_args=('-dmenu')
    declare -a mesg_rofi_args=('-mesg')

    printcmd() { printf '%s\0icon\x1f%s\n' "$@"; }

    declare -A gfx_icons=(
        [hybrid]='gpu-hybrid'
        [integrated]='gpu-integrated'
        [compute]='gpu-compute'
        [vfio]='gpu-vfio'
        [asusmuxdgpu]='gpu-nvidia'
        [nvidianomodeset]='gpu-nvidia'
        [undefined]='emblem-important'
    )
    declare -A power_icons=(
        [performance]='asus_notif_red'
        [balanced]='asus_notif_yellow'
        [quiet]='asus_notif_green'
        ['power-saver']='asus_notif_green'
        [undefined]='emblem-important'
    )
    declare -A od_icons=(
        [true]='emblem-checked'
        [false]='emblem-error'
        [undefined]='emblem-important'
    )
fi

declare -A opttext=(
    [power]='Power profile'
    [gfx]='GFX Mode'
    [od]='Panel Overdrive'
)

declare -a faildeps=()
for i in "${roficmd:-}" powerprofilesctl asusctl supergfxctl; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
# panic if missing essentials
if ((${#faildeps[@]})); then
    set +euo pipefail
    stuff="$(printf '%s\n' "${faildeps[@]}")"
    echo "Missing dependencies:"$'\n'"$stuff"
    notify-send -a "${0##*/}" "Missing dependencies" "$stuff"
    exit 1
fi

declare -a power_profiles=()
while read -r line; do
    power_profiles+=("${line}")
done < <(powerprofilesctl list | grep -oP '^(\*|\s)\s\K\S+(?=:.*)')

declare -a gfx_modes=()
while read -r line; do
    gfx_modes+=("$line")
done < <(supergfxctl -s | tr -s ' ' '\n' | grep -oP '[^\[\]\s,]+')

declare -i reset_mesg=1
while :; do
    unset new_opts cmdargs is_selection new_selection i_str current sel selected options current_power current_gfx current_od

    current_power="$(powerprofilesctl get || :)"
    current_gfx="$(supergfxctl -g || :)"
    current_od="$(asusctl bios -o | grep -oE '(true|false)$' || :)"

    declare -a options=(
        "${opttext[power]}${TAB}(${current_power:=undefined})"
        "${power_icons[${current_power,,}]}"
        "${opttext[gfx]}${TAB}(${current_gfx:=undefined})"
        "${gfx_icons[${current_gfx,,}]}"
        "${opttext[od]}${TAB}(${current_od:=undefined})"
        "${od_icons[$current_od]}"
    )

    ((reset_mesg)) && declare -a mesg=("${0##*/} -- select an option to modify" 'Press ESC to cancel')

    selected="$(printcmd "${options[@]}" | $roficmd "${rofi_args[@]}" "${mesg_rofi_args[@]}" "${mesg[*]}" | sed 's/(//g ; s/)//g')"
    sel="${selected%"$TAB"*}"
    current="${selected##*"$TAB"}"

    declare -a new_opts=()
    cmd='echo'
    declare -a cmdargs=()
    declare -i is_selection=1
    reset_mesg=1

    case "${sel:-}" in
    "${opttext[power]}")
        cmd=powerprofilesctl
        cmdargs+=(set)
        for i in "${power_profiles[@]}"; do
            if [[ "$i" == "$current" ]]; then
                i_str="${i}${TAB}(current)"
            else
                i_str="$i"
            fi
            new_opts+=("$i_str" "${power_icons[${i,,}]}")
        done
        ;;
    "${opttext[gfx]}")
        cmd=supergfxctl
        cmdargs+=(-m)
        for i in "${gfx_modes[@]}"; do
            if [[ "$i" == "$current" ]]; then
                i_str="${i}${TAB}(current)"
            else
                i_str="$i"
            fi
            new_opts+=("$i_str" "${gfx_icons[${i,,}]}")
        done
        ;;
    "${opttext[od]}")
        cmd=asusctl
        cmdargs+=(bios -O)
        case "$current" in
        true)
            cmdargs+=(false)
            ;;
        false)
            cmdargs+=(true)
            ;;
        *)
            exit 1
            ;;
        esac
        is_selection=0
        ;;
    *)
        exit 1
        ;;
    esac

    if ((is_selection)); then
        new_selection="$(printcmd "${new_opts[@]}" | $roficmd "${rofi_args[@]}")"

        case "${new_selection:=}" in
        *'(current)')
            mesg+=("Already selected this mode! (${sel:-} ${new_selection%"$TAB"*})")
            reset_mesg=0
            continue
            ;;
        '')
            exit 1
            ;;
        *)
            cmdargs+=("$new_selection")
            ;;
        esac
    fi

    $cmd "${cmdargs[@]}"
    echo 'ran command:' "$cmd" "${cmdargs[@]}"

done

#!/usr/bin/env bash

_iconify () {
    local icon="${1:?Error, must specify an icon!}"
    local type="${2:-}"
    local icon_color='#FFFFFF'

    case "$type" in
        'urgent')
            icon_color="${ROFI_URGENT:-#000000}"
        ;;
        'active')
            icon_color="${ROFI_ACTIVE:-#000000}"
        ;; *)
            icon_color="${ROFI_NORMAL:-$icon_color}"
        ;;
    esac

    printf "<span color='%s'>%s</span>" "$icon_color" "$icon"
}

DMENU_COMMAND="rofi -dmenu -mesg"

power_profiles=''
power_profile_current=''
while read line; do
    line="${line/:}"
    if [[ "${line:: 1}" == '*' ]]; then
        power_profile_current="${line:2}"
    fi
    power_profiles="$power_profiles ${line/\* }"
done < <(powerprofilesctl list | grep '^. [a-z]')
power_profiles="${power_profiles/ }"


gfx_current="$(supergfxctl -g)"
gfx_modes="$(supergfxctl -s)"
gfx_modes="${gfx_modes:1:-1}"
gfx_modes="${gfx_modes/,}"
gfx_modes="${gfx_modes,,}"

overdrive="$(asusctl bios -o)"
overdrive="${overdrive/Panel overdrive on: }"

case "${power_profile_current}" in
    'performance')
        power_profile_icon="$(_iconify )"
    ;; 'balanced')
        power_profile_icon="$(_iconify )"
    ;; 'power-saver')
        power_profile_icon="$(_iconify 󰌪)"
    ;;
esac

case "$overdrive" in
    'true')
        overdrive_icon="$(_iconify 󱄄)"
    ;; 'false')
        overdrive_icon="$(_iconify 󰶐)"
    ;;
esac

case "$gfx_current" in
    'hybrid')
        gfx_current_icon="$(_iconify 󰢮)"
    ;; 'integrated')
        gfx_current_icon="$(_iconify 󰘚)"
    ;; *)
        gfx_current_icon="$(_iconify )"
    ;;
esac

power_profile_choice="Power profile (${power_profile_current^})"
gfx_mode_current="GFX mode (${gfx_current^})"
overdrive_current="Panel Overdrive toggle (${overdrive^})"

configuration_choice="$(printf "${power_profile_choice}\0icon\x1f$power_profile_icon
${gfx_mode_current}\0icon\x1f$gfx_current_icon
${overdrive_current}\0icon\x1f${overdrive_icon}" | $DMENU_COMMAND 'gfxmenu.sh')"

case "$configuration_choice" in
    "$power_profile_choice")
        power_profile_array="${power_profiles// /\\n}"
        power_profile_decision="$(printf "${power_profile_array//$power_profile_current/$power_profile_current\\0icon\\x1f$power_profile_icon}" | $DMENU_COMMAND 'Choose your power profile')"
        if [ -n "$power_profile_decision" ]; then
            powerprofilesctl set "$power_profile_decision"
            notify-send -a 'gfxmenu.sh' 'Power Profile' "set power profile to '$power_profile_decision'"
        else
            echo "Please choose a power profile!"
            exit 1
        fi
    ;; "$gfx_mode_current")
        gfx_mode_array="${gfx_modes// /\\n}"
        gfx_mode_decision="$(printf "${gfx_mode_array//$gfx_current/$gfx_current\\0icon\\x1f$gfx_current_icon}" | $DMENU_COMMAND 'Choose your supergfxctl mode')"
        if [ -n "$gfx_mode_decision" ]; then
            supergfxctl -m "$gfx_mode_decision"
            notify-send -a 'gfxmenu.sh' 'GFX mode' "set GFX mode to '$gfx_mode_decision'. Log out to apply."
        else
            echo "Please choose a gfx mode!"
            exit 1
        fi
    ;; "$overdrive_current")
        if [[ "$overdrive" == "true" ]]; then
            overdrive_decision=false
        elif [[ "$overdrive" == "false" ]]; then
            overdrive_decision=true
        fi
        asusctl bios -O "$overdrive_decision"
        notify-send -a 'gfxmenu.sh' 'Panel overdrive' "Panel overdrive set to '$overdrive_decision'"
    ;; *)
        exit 1
    ;;
esac

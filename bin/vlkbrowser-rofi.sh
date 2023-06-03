#!/usr/bin/env bash

URL="${1:?Error: Please input a URL!}"

# gtk-icon=Name Browser=/command/for/browser
browsers=(
    "path-combine=Copy URL=echo -n * | xclip -selection clipboard"
    "firefox=Firefox=flatpak run org.mozilla.firefox *"
    "net.waterfox.waterfox=Waterfox=flatpak run net.waterfox.waterfox *"
    "brave=Brave Browser=flatpak run com.brave.Browser *"
    "chromium=Chromium Freeworld=chromium-freeworld *"
)

_print_browsers () {
    for i in "${browsers[@]}"; do
        local icon="${i%%=*}"
        local command="${i##*=}"
        local name="${i#*=}"
        name="${name%=*}"
        echo -e "${name} => ${command}\0icon\x1f${icon}"
    done
}

browser="$(_print_browsers | rofi -dmenu -mesg "${URL//&/&amp;}")"
command="${browser#*=> }"
exec sh -c "${command//\*/\'$URL\'}"

#!/usr/bin/bash

__swaylock () {
    exec swaylock -Ffli "$IMAGE" \
        --font "$FONT" \
        --font-size "$FONT_SIZE" \
        --indicator-radius "$LOCK_RADIUS" \
        --indicator-thickness "$LOCK_WIDTH" \
        --inside-color "$LOCK_INSIDE" \
        --inside-ver-color "$VERIF_BG_ACCENT" \
        --inside-wrong-color "$WRONG_BG_ACCENT" \
        --key-hl-color "$LOCK_KEY_ACCENT" \
        --line-color '00000000' \
        --ring-color "$LOCK_ACCENT" \
        --ring-ver-color "$VERIF_ACCENT" \
        --ring-wrong-color "$WRONG_ACCENT" \
        --text-color "$FONT_COLOR" \
        --text-ver-color "$FONT_COLOR" \
        --text-wrong-color "$FONT_COLOR"
}

__i3lock () {
    exec i3lock -efti "$IMAGE"
}

__i3lock_color () {
    exec i3lock -Ffki "$IMAGE" \
        --greeter-text='' \
        --wrong-text='Access Denied' \
        --verif-text='Please Wait' \
        --noinput-text='Field Cleared' \
        --time-str='%r' \
        --date-str='%A %B %-d, %Y' \
        --time-pos='ix:130' \
        --date-pos='ix:1000' \
        --pass-media-keys --pass-screen-keys --pass-power-keys --pass-volume-keys --ignore-empty-password \
        --time-color="$FONT_COLOR" \
        --date-color="$FONT_COLOR" \
        --greeter-color="$FONT_COLOR" \
        --verif-color="$FONT_COLOR" \
        --wrong-color="$FONT_COLOR" \
        --modif-color="$FONT_COLOR" \
        --time-font="$FONT" \
        --date-font="$FONT" \
        --layout-font="$FONT" \
        --verif-font="$FONT" \
        --wrong-font="$FONT" \
        --greeter-font="$FONT" \
        --timeoutline-color="$FONT_OUTLINE" \
        --dateoutline-color="$FONT_OUTLINE" \
        --layoutoutline-color="$FONT_OUTLINE" \
        --verifoutline-color="$FONT_OUTLINE" \
        --wrongoutline-color="$FONT_OUTLINE" \
        --greeteroutline-color="$FONT_OUTLINE" \
        --timeoutline-width="$FONT_LARGE_OUTLINE_SIZE" \
        --dateoutline-width="$FONT_LARGE_OUTLINE_SIZE" \
        --layoutoutline-width="$FONT_OUTLINE_SIZE" \
        --verifoutline-width="$FONT_OUTLINE_SIZE" \
        --wrongoutline-width="$FONT_OUTLINE_SIZE" \
        --greeteroutline-width="$FONT_OUTLINE_SIZE" \
        --time-size="$FONT_MEME_SIZE" \
        --date-size="$FONT_MEME_SIZE" \
        --layout-size="$FONT_SIZE" \
        --verif-size="$FONT_SIZE" \
        --wrong-size="$FONT_SIZE" \
        --greeter-size="$FONT_SIZE" \
        --radius "$LOCK_RADIUS" \
        --inside-color="$LOCK_INSIDE" \
        --ring-width="$LOCK_WIDTH" \
        --line-color='00000000' \
        --keyhl-color="$LOCK_KEY_ACCENT" \
        --separator-color="$LOCK_KEY_ACCENT_BORDER" \
        --ring-color="$LOCK_ACCENT" \
        --ringver-color="$VERIF_ACCENT" \
        --insidever-color="$VERIF_BG_ACCENT" \
        --ringwrong-color="$WRONG_ACCENT" \
        --insidewrong-color="$WRONG_BG_ACCENT"
}


if pgrep 'i3lock' || pgrep 'swaylock'; then
    notify-send 'Error! screenlocker already detected!'
    date +'%x %X -- vlklock fail' >> "${XDG_CACHE_HOME:-$HOME/.cache}/vlklock-log"
    exit 1
fi

IMAGE="$(printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/backgrounds/vlklock/"* | shuf | head -n 1)"
IMAGE="${IMAGE:-/usr/share/backgrounds/default.png}"

FONT=Impact

FONT_COLOR=FFFFFF
FONT_OUTLINE=000000
FONT_SIZE=64
FONT_MEME_SIZE=128
FONT_OUTLINE_SIZE=1
FONT_LARGE_OUTLINE_SIZE=3

LOCK_WIDTH=16.0
LOCK_RADIUS=220
LOCK_INSIDE=FFFFFF00

LOCK_ACCENT=D55FDE
LOCK_KEY_ACCENT=7B57FF
LOCK_KEY_ACCENT_BORDER=5B37CF

VERIF_ACCENT=fcf11b
VERIF_BG_ACCENT="${VERIF_ACCENT}70"
WRONG_ACCENT=ff0000
WRONG_BG_ACCENT="${WRONG_ACCENT}70"


if [ -z "$WAYLAND_DISPLAY" ]; then
    __i3lock_color
    #__i3lock
else
    __swaylock
fi

#vlkbg


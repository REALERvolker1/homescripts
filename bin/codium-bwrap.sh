#!/usr/bin/env bash
set -euo pipefail

echo "This program is a piece of shit that does not work.
I wrote it because I wanted to unshare my home dir with codium,
but it is very complicated.

Here's a few resources in case I want to investigate this again.

https://github.com/valoq/bwscripts/blob/master/profiles/signal-desktop
https://github.com/valoq/bwscripts/tree/master/profiles
https://wiki.archlinux.org/title/Bubblewrap

In the meantime, I will open 'codium' for you."

exec codium "$@"

exit $?

if [ ! -z "$(pgrep --uid "$(id -u)" codium)" ]; then
    echo "codium already running"
    exit
fi

declare -a args=(bwrap)
declare -a addargs=(/usr/bin/zypak-wrapper /usr/bin/codium -w)

declare -a robinds=(
    /usr/bin
    /usr/share
    /usr/lib
    /lib{,64}
    /{s,}bin
    /etc
)

if [[ -n ${WAYLAND_DISPLAY-} ]]; then
    robinds+=("$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY")
    addargs+=(--enable-features=UseOzonePlatform -ozone-platform=wayland)
elif [[ -n ${DISPLAY-} ]]; then
    robinds+=(
        "$XAUTHORITY"
        "/tmp/.X11-unix/X${DISPLAY##*:}"
    )
else
    echo "Error, you must be running in a graphical session!"
    exit 1
fi

robinds+=(
    "$XDG_RUNTIME_DIR/pipewire-0"{,.lock}
)

for i in "${robinds[@]}"; do
    [[ -e $i ]] && args+=('--ro-bind' "$i" "$i")
done

args+=(
    --proc /proc
    --dev /dev
)

binds=(
    "/${DBUS_SESSION_BUS_ADDRESS#*/}"
)

for i in "${binds[@]}"; do
    [[ -e $i ]] && args+=('--bind' "$i" "$i")
done

args+=("${addargs[@]}")

echo "${args[@]}"

"${args[@]}"

exit $?

#--ro-bind /run/user/"$(id -u)"/"$WAYLAND_DISPLAY" /run/user/"$(id -u)"/"$WAYLAND_DISPLAY" \
(
    exec bwrap \
        --ro-bind /usr/bin/sh /usr/bin/sh \
        --ro-bind /usr/bin/codium /usr/bin/codium \
        --ro-bind /usr/bin /usr/bin \
        --ro-bind /usr/share /usr/share/ \
        --ro-bind /usr/lib /usr/lib \
        --ro-bind /usr/lib64 /usr/lib64 \
        --symlink /usr/lib64 /lib64 \
        --symlink /usr/lib /lib \
        --symlink /usr/bin /bin \
        --symlink /usr/bin /sbin \
        --proc /proc \
        --dev /dev \
        --dev-bind-try /dev/hidraw0 /dev/hidraw0 \
        --dev-bind-try /dev/hidraw1 /dev/hidraw1 \
        --dev-bind-try /dev/hidraw2 /dev/hidraw2 \
        --dev-bind-try /dev/hidraw3 /dev/hidraw3 \
        --dev-bind-try /dev/hidraw4 /dev/hidraw4 \
        --dev-bind-try /dev/hidraw5 /dev/hidraw5 \
        --dev-bind-try /dev/hidraw6 /dev/hidraw6 \
        --dev-bind-try /dev/hidraw7 /dev/hidraw7 \
        --dev-bind-try /dev/hidraw8 /dev/hidraw8 \
        --dev-bind-try /dev/hidraw9 /dev/hidraw9 \
        --dev-bind-try /dev/char /dev/char \
        --dev-bind-try /dev/usb /dev/usb \
        --dev-bind-try /dev/dri /dev/dri \
        --ro-bind-try /sys/bus/usb /sys/bus/usb \
        --ro-bind-try /sys/class/hidraw /sys/class/hidraw \
        --ro-bind-try /sys/dev /sys/dev \
        --ro-bind-try /sys/devices /sys/devices \
        --ro-bind /etc/passwd /etc/passwd \
        --ro-bind /etc/group /etc/group \
        --ro-bind /etc/hostname /etc/hostname \
        --ro-bind /etc/hosts /etc/hosts \
        --ro-bind /etc/localtime /etc/localtime \
        --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
        --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
        --ro-bind-try /etc/xdg /etc/xdg \
        --ro-bind-try /etc/gtk-2.0 /etc/gtk-2.0 \
        --ro-bind-try /etc/gtk-3.0 /etc/gtk-3.0 \
        --ro-bind-try /etc/fonts /etc/fonts \
        --ro-bind-try /etc/mime.types /etc/mime.types \
        --ro-bind-try /etc/alsa /etc/alsa \
        --ro-bind-try /etc/pulse /etc/pulse \
        --ro-bind-try /etc/pipewire /etc/pipewire \
        --tmpfs /run \
        --ro-bind-try /run/user/"$(id -u)"/pipewire-0 /run/user/"$(id -u)"/pipewire-0 \
        --ro-bind-try /run/user/"$(id -u)"/pulse /run/user/"$(id -u)"/pulse \
        --bind-try ~/Downloads ~/Downloads \
        --bind-try ~/.vscode-oss-bak ~/.vscode-oss \
        --unshare-all \
        --share-net \
        --hostname mypc \
        --new-session \
        \
        /usr/bin/zypak-wrapper /usr/bin/codium -w
)
# --unsetenv DBUS_SESSION_BUS_ADDRESS \
#/usr/bin/codium # 10</usr/local/bin/seccomp_default_filter.bpf
#--seccomp 10 \

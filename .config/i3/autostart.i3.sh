#!/dev/null
# vim:foldmethod=marker:ft=i3config

# x11 stuff
$exec xrdb -merge "$XRESOURCES"
#$exec xlayoutdisplay

# DE stuff
$exec /usr/lib/xfce-polkit/xfce-polkit
$exec dbus-update-activation-environment --systemd --verbose DISPLAY XAUTHORITY WAYLAND_DISPLAY
#$exec gnome-keyring-daemon -r
#$exec nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" -l
#$exec autostart_keyring.sh
$exec ~/.local/lib/hardcoded-keyring-unlocker

$exec volbright.sh --brightness --volume --keyboard

# Power management
$exec xset -dpms
$exec xss-lock -l "vlklock.sh"
$exec pmgmt.sh
$exec "killall xplugd; xplugd"

# Input configs
$exec numlockx
$exec pointer.sh -n
$exec xmodmap -e "clear lock"
$exec xmodmap -e "keycode 66 = Escape NoSymbol Escape"

# Bar icons
$exec xfce4-clipman
$exec nm-applet

# visuals
$exec picom
$exec flashfocus
$exec "killall gammastep; gammastep -P"
$exec hsetroot -cover "$XDG_DATA_HOME/backgrounds/DiscoDingoUbuntu.png"

#$exec scratchpad_terminal.sh

# exec_always field
#$execa hsetroot -cover "$(printf '%s\n' $XDG_DATA_HOME/backgrounds/* | shuf | head -n 1)"
$execa kitti3 -s 0.75 1.0 -p RC


$exec autostart-remove.sh
$exec autostart-dbus-activation-env.sh
$exec xhost +local:
$exec autostart-keyring.sh
$exec autostart-polkit.sh

$exec ydotoold
$exec asusctl -c 80

$exec autostart-gammastep.sh
$exec dunst

$exec nm-applet
$exec set-cursor-theme.sh --session

$exec pmgmt.sh
$exec autostart-clipboard.sh


#!/dev/null
#: vim:foldmethod=marker:ft=i3config
floating_modifier $mod

# Commands {{{

# vlkenv {{{

bindsym $mod + d $exec rofi -show drun
#bindsym $mod + d $exec rofi -modi 'drun,run' -show drun -sidebar-mode
bindsym $mods + d $exec rofi -show run
bindsym $modc + d $exec wofi -S drun

bindsym $mod + Tab $exec rofi -modi window -show window

bindsym --release $mod + BackSpace $exec vlk-sensible-browser 1
bindsym --release $mods + BackSpace $exec vlk-sensible-browser 2
bindsym --release $modc + BackSpace $exec vlk-sensible-browser 3

bindsym --release $mod + z $exec vlk-sensible-browser 1
bindsym --release $mods + z $exec vlk-sensible-browser 2
bindsym --release $modc + z $exec vlk-sensible-browser 3

bindsym --release $mod + backslash $exec nemo
bindsym --release $mods + backslash $exec mousepad
bindsym --release $modc + backslash $exec codium

bindsym --release $mod + x $exec nemo
bindsym --release $mods + x $exec mousepad
bindsym --release $modc + x $exec codium

bindsym $mod + Return $exec vlk-sensible-terminal 1
bindsym $mods + Return $exec vlk-sensible-terminal 2
bindsym $modc + Return $exec vlk-sensible-terminal 3
bindsym $mod + t $exec vlk-sensible-terminal 1
bindsym $mods + t $exec vlk-sensible-terminal 2
bindsym $modc + t $exec vlk-sensible-terminal 3

bindsym $mod + period $exec rofi-charamap-menu.sh

bindsym XF86Calculator $exec gnome-calculator
bindsym --release $mod + KP_Enter $exec gnome-calculator

bindsym --release Print $exec flameshot gui
#bindsym --release Print $exec vlk-sensible-screenshot 1
bindsym --release shift + Print $exec vlk-sensible-screenshot 2
bindsym --release ctrl + shift + Print $exec vlk-sensible-screenshot 3
bindsym --release $mod + Print $exec vlk-sensible-screenshot 1
bindsym --release $mods + Print $exec vlk-sensible-screenshot 2
bindsym --release $modc + Print $exec vlk-sensible-screenshot 3

bindsym $mod + Escape $exec rofi -show powermenu

bindsym $mod + equal $exec vlklock.sh

bindsym $mod + XF86Launch3 $exec gfxmenu.sh
bindsym $mods + XF86Launch3 $exec $XDG_CONFIG_HOME/bar-scripts/bluetooth-bar.sh --toggle
bindsym $mod + Scroll_Lock $exec gfxmenu.sh
bindsym $mods + Scroll_Lock $exec $XDG_CONFIG_HOME/bar-scripts/bluetooth-bar.sh --toggle

# }}}
# Media ctrl {{{

bindsym XF86AudioMute $exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86AudioMicMute $exec playerctl play-pause

bindsym XF86AudioRaiseVolume $exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume $exec pactl set-sink-volume @DEFAULT_SINK@ -5%

bindsym $mods +  XF86AudioRaiseVolume $exec playerctl position 5+
bindsym $mods + XF86AudioLowerVolume $exec playerctl position 5-

bindsym $mod + XF86AudioRaiseVolume $exec playerctl next
bindsym $mod + XF86AudioLowerVolume $exec playerctl previous

# }}}
# Special keys {{{

bindsym XF86Launch3 nop kitti3
bindsym Scroll_Lock nop kitti3

# Asus Aura key (Unused potential)
bindsym XF86Launch4 $exec "dunstify -a $XDG_CURRENT_DESKTOP -- asusctl 'Aura mode not changed -- not configured'"

# Brightness key
bindsym XF86MonBrightnessUp $exec light -A 10
bindsym XF86MonBrightnessDown $exec light -U 10

# Touchpad toggle
bindsym XF86TouchpadToggle $exec pointer.sh -t
bindsym $mod + F10 $exec pointer.sh -t

# }}}
# Other commands {{{

bindsym $mod + p $exec "ps -A | grep 'picom' && killall picom || picom"
bindsym $mods + p $exec "killall picom && picom"

bindsym $alt + h $exec ydotool key '102:1' '102:0' # home
bindsym $alt + l $exec ydotool key '107:1' '107:0' # end
bindsym $alt + Left $exec ydotool key '102:1' '102:0'
bindsym $alt + Right $exec ydotool key '107:1' '107:0'

# }}}

# }}}
# Wm ctrl {{{

bindsym $mod + r reload
bindsym $mods + r restart

bindsym $mod + q kill
bindsym $mods + q $exec xkill
bindsym $alt + F4 $exec "dunstify -a $XDG_CURRENT_DESKTOP -i 'face-laugh' -- 'lmao you thought'"
bindsym $alt + F3 $exec "dunstify -a $XDG_CURRENT_DESKTOP -i 'face-cool' -- '🤙🤙🤙🤙🤙🤙🤙🤙🤙🤙🤙🤙🤙'"

bindsym $mod + c open

bindsym $mod + v split toggle
bindsym $mod + f fullscreen toggle

bindsym $mod + slash border toggle
bindsym $mods + slash bar mode toggle

#bindsym $mod + s layout stacking
bindsym $mod + w layout tabbed
bindsym $mod + e layout toggle split

bindsym $mod + space focus mode_toggle
bindsym $mods + space floating toggle

bindsym $mod + grave gaps inner current set $gapsize-alt
bindsym $mods + grave gaps inner current set $gapsize

#bindsym $mod + comma $exec "i3-msg 'mark --toggle pinned' && i3-msg floating toggle && i3-msg sticky toggle"
bindsym $mod + comma $exec i3-msg sticky toggle

# }}}
# motion binds {{{

# focus {{{

bindsym $mod + h focus left
bindsym $mod + j focus down
bindsym $mod + k focus up
bindsym $mod + l focus right

bindsym $mod + Left focus left
bindsym $mod + Down focus down
bindsym $mod + Up focus up
bindsym $mod + Right focus right

# }}}
# movement {{{

bindsym $mods + h move left
bindsym $mods + j move down
bindsym $mods + k move up
bindsym $mods + l move right

bindsym $mods + Left move left
bindsym $mods + Down move down
bindsym $mods + Up move up
bindsym $mods + Right move right

# }}}
# output focus {{{

bindsym $modc + h focus output left
bindsym $modc + j focus output down
bindsym $modc + k focus output up
bindsym $modc + l focus output right

bindsym $modc + Left focus output left
bindsym $modc + Down focus output down
bindsym $modc + Up focus output up
bindsym $modc + Right focus output right

# }}}
# output movement {{{

bindsym $modcs + h move output left; focus output left
bindsym $modcs + j move output down; focus output left
bindsym $modcs + k move output up; focus output left
bindsym $modcs + l move output right; focus output left

bindsym $modcs + Left move output left; focus output left
bindsym $modcs + Down move output down; focus output down
bindsym $modcs + Up move output up; focus output up
bindsym $modcs + Right move output right; focus output right

# }}}
# resize small {{{

bindsym $moda + h resize shrink width 10px or 10 ppt
bindsym $moda + j resize grow height 10px or 10 ppt
bindsym $moda + k resize shrink height 10px or 10 ppt
bindsym $moda + l resize grow width 10px or 10 ppt

bindsym $moda + Left resize shrink width 10px or 10 ppt
bindsym $moda + Down resize grow height 10px or 10 ppt
bindsym $moda + Up resize shrink height 10px or 10 ppt
bindsym $moda + Right resize grow width 10px or 10 ppt

# }}}
# resize large {{{

bindsym $modas + h resize shrink width 30px or 30 ppt
bindsym $modas + j resize grow height 30px or 30 ppt
bindsym $modas + k resize shrink height 30px or 30 ppt
bindsym $modas + l resize grow width 30px or 30 ppt

bindsym $modas + Left resize shrink width 30px or 30 ppt
bindsym $modas + Down resize grow height 30px or 30 ppt
bindsym $modas + Up resize shrink height 30px or 30 ppt
bindsym $modas + Right resize grow width 30px or 30 ppt

# }}}

# }}}
# Workspaces {{{

bindsym $mod + 1 workspace number $ws1
bindsym $mod + 2 workspace number $ws2
bindsym $mod + 3 workspace number $ws3
bindsym $mod + 4 workspace number $ws4
bindsym $mod + 5 workspace number $ws5
bindsym $mod + 6 workspace number $ws6
bindsym $mod + 7 workspace number $ws7
bindsym $mod + 8 workspace number $ws8
bindsym $mod + 9 workspace number $ws9
bindsym $mod + 0 workspace number $ws10

bindsym $mods + 1 move container to workspace number $ws1
bindsym $mods + 2 move container to workspace number $ws2
bindsym $mods + 3 move container to workspace number $ws3
bindsym $mods + 4 move container to workspace number $ws4
bindsym $mods + 5 move container to workspace number $ws5
bindsym $mods + 6 move container to workspace number $ws6
bindsym $mods + 7 move container to workspace number $ws7
bindsym $mods + 8 move container to workspace number $ws8
bindsym $mods + 9 move container to workspace number $ws9
bindsym $mods + 0 move container to workspace number $ws10

# scratchpad
bindsym $mod + minus scratchpad show
bindsym $mods + minus move scratchpad
#bindsym XF86Launch3 scratchpad show
#bindsym Shift + XF86Launch3 move scratchpad

# }}}

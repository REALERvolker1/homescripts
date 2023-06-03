#!/dev/null
#: vim:foldmethod=marker:ft=i3config

#: check out https://github.com/yusufaktepe/dotfiles/blob/tp/.config/i3/config

# WindowTypes {{{

for_window [class="__scratchpad"] move scratchpad, resize set 1200 900

for_window [class="__float"] floating enable, resize set 900 800

#for_window [title="^__scratchpad_terminal__$"] move position 520 0, resize set 1400 1080, move scratchpad
#for_window [class="^__scratchpad_terminal__$"] move position 520 0, resize set 1400 1080, move scratchpad

for_window [window_role="pop-up"] floating enable
for_window [window_role="bubble"] floating enable
for_window [window_role="task_dialog"] floating enable
for_window [window_role="Preferences"] floating enable
for_window [window_type="dialog"] floating enable
for_window [window_type="popup_menu"] floating enable
for_window [window_type="menu"] floating enable
for_window [window_role="GtkFileChooserDialog"] resize set 1100 800, move position center

# }}}
# Workspaces {{{

assign [class="VSCodium"] workspace $ws1
#assign [class="(?i)firefox"] workspace $ws2
assign [class="LibreWolf"] workspace $ws2
#assign [class="Mullvad Browser"] workspace $ws2
assign [class="Opera"] workspace $ws3
assign [class="Brave-browser"] workspace $ws4
assign [class="(?i)steam"] workspace $ws5
assign [class="discord"] workspace $ws6

# }}}
# Settings managers {{{

for_window [class="Kvantum"] floating enable

for_window [class="(?i)azote~"] floating enable
for_window [class="Nitrogen"] floating enable

for_window [class="(?i)arandr"] floating enable
for_window [class="Nm-connection-editor"] floating enable
for_window [class="(?i)blueman-manager"] floating enable
for_window [class="(?i)pavucontrol"] floating enable
for_window [class="(?i)pavucontrol-qt"] floating enable border none
for_window [class="(?i)blueman-manager"] floating enable border none
for_window [class="Kvantum Manager"] border none

for_window [class="Dconf-editor"] floating enable

# }}}
# Shell {{{

for_window [class="Junction"] floating enable sticky enable
for_window [class="Xfce-polkit"] floating enable sticky enable

for_window [class="XEyes"] floating enable border none
for_window [class="^$" title="Event Tester"] floating enable

for_window [class="^$" title="^xfdashboard$"] floating enable sticky enable
for_window [class="Plank"] floating enable sticky enable

for_window [class="Zenity"] floating enable border none
for_window [class="Wofi"] sticky enable border none

for_window [class="(?i)flameshot"] floating enable sticky enable
for_window [class="ksnip"] floating enable
for_window [class="spectacle"] floating enable

# }}}

# PC apps {{{

for_window [class="(?i)file-roller"] floating enable border none
for_window [class="baobab"] floating enable

for_window [class="Gucharmap"] floating enable
for_window [class="org.gnome.Characters"] floating enable border none
for_window [class="(?i)audacious"] floating enable border none

for_window [class="(?i)setroubleshoot"] floating enable

for_window [class="^dolphin$" title="^Download New Stuff"] floating enable

for_window [class="gnome-calculator"] floating enable
for_window [class="(?i)gpick"] floating enable border none

# }}}
# General apps {{{

for_window [class="URxvt"] floating enable
for_window [class="qutebrowser"] floating enable

for_window [class="(?i)zoom"] floating enable
for_window [class="Authy Desktop"] floating enable border none

for_window [class="mpv"] floating enable sticky enable resize set 1280 720
for_window [class="Ristretto"] floating enable resize set 900 700
for_window [class="Apostrophe"] border none
for_window [class="(?i)audacious"] floating enable

#for_window [class="Minecraft.*"] floating enable border none
for_window [class="quadrapassel"] floating enable

for_window [class="librewolf" title="^Picture-in-Picture$"] sticky enable border none
for_window [class="firefox" title="^Picture-in-Picture$"] sticky enable border none

for_window [class="org.gnome.Software"] border none

# }}}

# Steam {{{

# Have not figured out how to get the friend chat floating
for_window [class="^Steam$" title="^Friends$"] floating enable
for_window [class="^Steam$" title="^Friends List$"] floating enable
for_window [class="^Steam$" title="Steam - News"] floating enable
for_window [class="^Steam$" title=".* - Chat"] floating enable
for_window [class="^Steam$" title="^Settings$"] floating enable
for_window [class="^Steam$" title=".* - event started"] floating enable
for_window [class="^Steam$" title=".* CD key"] floating enable
for_window [class="^Steam$" title="^Steam - Self Updater$"] floating enable
for_window [class="^Steam$" title="^Screenshot Uploader$"] floating enable
for_window [class="^Steam$" title="^Steam Guard - Computer Authorization Required$"] floating enable
for_window [title="^Steam Keyboard$"] floating enable

# }}}

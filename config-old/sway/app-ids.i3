#!/dev/null
#: vim:foldmethod=marker:ft=i3config

#: check out https://github.com/yusufaktepe/dotfiles/blob/tp/.config/i3/config

# WindowTypes {{{

for_window [app_id="__scratchpad"] move scratchpad, resize set 1200 900

for_window [app_id="__float"] floating enable, resize set 900 800

#for_window [title="^__scratchpad_terminal__$"] move position 520 0, resize set 1400 1080, move scratchpad
#for_window [app_id="^__scratchpad_terminal__$"] move position 520 0, resize set 1400 1080, move scratchpad

# for_window [window_role="pop-up"] floating enable
# for_window [window_role="bubble"] floating enable
# for_window [window_role="task_dialog"] floating enable
# for_window [window_role="Preferences"] floating enable
# for_window [window_type="dialog"] floating enable
# for_window [window_type="popup_menu"] floating enable
# for_window [window_type="menu"] floating enable
# for_window [window_role="GtkFileChooserDialog"] resize set 1100 800, move position center

# }}}
# Workspaces {{{

assign [app_id="VSCodium"] workspace $ws1
assign [app_id="Code - OSS"] workspace $ws1
assign [app_id="(?i)firefox"] workspace $ws4
assign [app_id="LibreWolf"] workspace $ws2
#assign [app_id="Mullvad Browser"] workspace $ws2
#assign [app_id="Opera"] workspace $ws3
assign [app_id="Brave-browser"] workspace $ws3
assign [app_id="(?i)steam"] workspace $ws5
for_window [app_id="^$" title="^Steam$"] workspace $ws5
assign [app_id="discord"] workspace $ws6

# }}}
# Settings managers {{{

for_window [app_id="Kvantum"] floating enable

for_window [app_id="(?i)azote~"] floating enable
for_window [app_id="Nitrogen"] floating enable

for_window [app_id="(?i)arandr"] floating enable
for_window [app_id="Nm-connection-editor"] floating enable
for_window [app_id="(?i)blueman-manager"] floating enable
for_window [app_id="(?i)pavucontrol"] floating enable
for_window [app_id="(?i)pavucontrol-qt"] floating enable border none
for_window [app_id="(?i)blueman-manager"] floating enable border none
for_window [app_id="Kvantum Manager"] border none

for_window [app_id="Dconf-editor"] floating enable

# }}}
# Shell {{{

for_window [app_id="Junction"] floating enable sticky enable
for_window [app_id="Xfce-polkit"] floating enable sticky enable

for_window [app_id="XEyes"] floating enable border none
for_window [app_id="^$" title="Event Tester"] floating enable

for_window [app_id="^$" title="^xfdashboard$"] floating enable sticky enable
for_window [app_id="Plank"] floating enable sticky enable

for_window [app_id="Zenity"] floating enable border none
for_window [app_id="Wofi"] sticky enable border none

for_window [app_id="(?i)flameshot"] floating enable sticky enable
for_window [app_id="ksnip"] floating enable
for_window [app_id="spectacle"] floating enable

# }}}

# PC apps {{{

for_window [app_id="(?i)file-roller"] floating enable border none
for_window [app_id="baobab"] floating enable

for_window [app_id="Gucharmap"] floating enable
for_window [app_id="org.gnome.Characters"] floating enable border none
for_window [app_id="(?i)audacious"] floating enable border none

for_window [app_id="(?i)setroubleshoot"] floating enable

for_window [app_id="^dolphin$" title="^Download New Stuff"] floating enable

for_window [app_id="gnome-calculator"] floating enable
for_window [app_id="(?i)gpick"] floating enable border none

# }}}
# General apps {{{

for_window [app_id="URxvt"] floating enable
for_window [app_id="qutebrowser"] floating enable

for_window [app_id="(?i)zoom"] floating enable
for_window [app_id="Authy Desktop"] floating enable border none

for_window [app_id="mpv"] floating enable sticky enable resize set 1280 720
for_window [app_id="Ristretto"] floating enable resize set 900 700
for_window [app_id="Apostrophe"] border none
for_window [app_id="(?i)audacious"] floating enable

for_window [app_id="Minecraft.*"] floating enable border none
for_window [app_id="quadrapassel"] floating enable

for_window [app_id="librewolf" title="^Picture-in-Picture$"] sticky enable border none
for_window [app_id="firefox" title="^Picture-in-Picture$"] sticky enable border none

for_window [app_id="org.gnome.Software"] border none

# }}}

# Steam {{{

# Have not figured out how to get the friend chat floating
for_window [app_id="^Steam$" title="^Friends$"] floating enable
for_window [app_id="^Steam$" title="^Friends List$"] floating enable
for_window [app_id="^Steam$" title="Steam - News"] floating enable
for_window [app_id="^Steam$" title=".* - Chat"] floating enable
for_window [app_id="^Steam$" title="^Settings$"] floating enable
for_window [app_id="^Steam$" title=".* - event started"] floating enable
for_window [app_id="^Steam$" title=".* CD key"] floating enable
for_window [app_id="^Steam$" title="^Steam - Self Updater$"] floating enable
for_window [app_id="^Steam$" title="^Screenshot Uploader$"] floating enable
for_window [app_id="^Steam$" title="^Steam Guard - Computer Authorization Required$"] floating enable
for_window [title="^Steam Keyboard$"] floating enable

# new steam
for_window [app_id="^steam$" title="^Friends List$"] floating enable
for_window [app_id="^steam$" title="^Steam Settings$"] floating enable

# }}}

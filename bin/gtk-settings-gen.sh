#!/usr/bin/bash

gtk_decoration_layout='menu:close'
gtk_toolbar_style='GTK_TOOLBAR_BOTH'
gtk_toolbar_icon_size='GTK_ICON_SIZE_LARGE_TOOLBAR'
gtk_button_images=1
gtk_menu_images=1

gtk_application_prefer_dark_theme=true
gtk_theme_name='adw-gtk3-dark'
gtk_icon_theme_name='Newaita-reborn-deep-purple-dark'
gtk_font_name='sans-serif 11'

gtk_xft_antialias=1
gtk_xft_hinting=1
gtk_xft_hintstyle='hintmedium'
gtk_xft_rgba='rgb'

gtk_enable_event_sounds=0
gtk_enable_input_feedback_sounds=0

case "$1" in
'--gsettings')
    set_setting() {
        gsettings set org.gnome.desktop.interface "$1" "$2"
    }
    set_setting 
    ;;
'--xsettings')
    xsettings_config="${XDG_CONFIG_HOME:-$HOME/.config}/xsettingsd/xsettingsd.conf"
    mkdir -p "${xsettings_config%/*}"
    echo -n '' >"$xsettings_config"
    ;;
'--gtk')
    gtk3_config="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
    gtk4_config="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"
    ;;
esac

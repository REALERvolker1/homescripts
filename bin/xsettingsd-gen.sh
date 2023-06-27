#!/usr/bin/bash
set -euo pipefail


#gtksettings="$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini")"

# cursor theme
[ -z "${XCURSOR_THEME:-}" ] && XCURSOR_THEME="$(grep -oP '^Inherits=\K.*' /usr/share/icons/default/index.theme)"
xsettings+=("Gtk/CursorThemeName ${XCURSOR_THEME:-Adwaita}")

#cat <(sed "
xsettingsd --config=<(sed "
s|gtk-cursor-theme-name|Gtk/CursorThemeName|g
s|gtk-cursor-blink|Net/CursorBlink|g
s|gtk-cursor-blink-time|Net/CursorBlinkTime|g
s|gtk-dnd-drag-threshold|Net/DndDragThreshold|g
s|gtk-double-click-distance|Net/DoubleClickDistance|g
s|gtk-double-click-time|Net/DoubleClickTime|g
s|gtk-enable-event-sounds|Net/EnableEventSounds|g
s|gtk-enable-input-feedback-sounds|Net/EnableInputFeedbackSounds|g
s|gtk-icon-theme-name|Net/IconThemeName|g
s|gtk-sound-theme-name|Net/SoundThemeName|g
s|gtk-theme-name|Net/ThemeName|g
s|gtk-xft-antialias|Xft/Antialias|g
s|gtk-xft-dpi|Xft/DPI|g
s|gtk-xft-hintstyle|Xft/HintStyle|g
s|gtk-xft-hinting|Xft/Hinting|g
s|gtk-xft-rgba|Xft/RGBA|g
s|gtk-button-images|Gtk/ButtonImages|g
s|gtk-menu-images|Gtk/MenuImages|g
s|gtk-toolbar-style|Gtk/ToolbarStyle|g
s|gtk-toolbar-icon-size|Gtk/ToolbarIconSize|g
s|gtk-font-name|Gtk/FontName|g
s/=/ /g
" "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini" | grep '^[A-Z]'
)

#s|gtk-decoration-layout|Gtk/DecorationLayout|g

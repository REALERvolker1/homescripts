#!/bin/bash

name='codium'
githubrepo='VSCodium/vscodium'
payload='VSCodium-linux-x64-*.tar.gz'
decompresscmd='tar -xzf'

cmds="if [ ! -f '$XDG_DATA_HOME/applications/codium.desktop' ]; then
    printf '%s\n' \
        '[Desktop Entry]' \
        'Name=VSCodium (portable)' \
        'Comment=Code Editing. Redefined.' \
        'Exec=codium' \
        'Icon=codium' \
        'Categories=TextEditor;Development;IDE;' \
        'MimeType=text/plain;application/x-codium-workspace;' \
        'Keywords=vscode;' \
        'Type=Application' \
        'StartupNotify=false' \
    >'$XDG_DATA_HOME/applications/codium.desktop'
fi
mkdir -p \"\${PWD:=\$(pwd)}/data/user-data\"
ln -sf \"\$PWD/bin/codium\" \"$HOME/.local/bin/\"
[ ! -e \"$XDG_CONFIG_HOME/VSCodium\" ] && ln -sf \"\$PWD/user-data\" \"$XDG_CONFIG_HOME/VSCodium\"
_icon_install \"\$PWD/resources/app/resources/linux/code.png\" 'codium.png'
"

# for i in 16 24 32 48 64 128 256; do
#     i_target=\"$XDG_DATA_HOME/icons/hicolor/\$ix\$i/apps/codium.png\"
#     [ -f \"\$i_target\" ] && continue
#     convert \"\$PWD/resources/app/resources/linux\" -resize \"\$i/\$i\" \"\$i_target\"
# done
# convert ./code.png -resize 64x64

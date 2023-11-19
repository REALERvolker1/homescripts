#!/bin/sh
set -eu

echo deprecated script, exiting
exit 1

folder="${0%/*}/src/xmlgen"
mkdir -p "$folder"

zbus-xmlgen --system org.freedesktop.UPower /org/freedesktop/UPower/devices/DisplayDevice >"$folder/upowerproxy.rs"

zbus-xmlgen --system org.supergfxctl.Daemon /org/supergfxctl/Gfx >"$folder/gfxproxy.rs"

zbus-xmlgen --system net.hadess.PowerProfiles /net/hadess/PowerProfiles >"$folder/powerprofilesproxy.rs"

# add each one to mod.rs manually

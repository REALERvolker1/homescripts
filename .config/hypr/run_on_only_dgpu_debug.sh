#!/usr/bin/env bash
export AQ_DRM_DEVICES="$(readlink -f /dev/dri/by-path/pci-0000:01:00.0-card)"

exec Hyprland

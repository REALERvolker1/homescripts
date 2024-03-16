#!/bin/sh

exec gnome-keyring-daemon --start --components=secrets

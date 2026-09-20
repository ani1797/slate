#!/bin/sh
# Auto-start Hyprland on tty1 for the live session's slate-user autologin.
#
# Guarded so it only fires for an interactive login shell on tty1 with no
# graphical session already running, and does nothing for other ttys, SSH
# logins, or non-interactive shells.
#
# Deliberately NOT `exec`'d: if Hyprland exits (e.g. it fails to start
# because of missing GPU/DRM support), falling back to the login shell
# keeps tty1 usable. Using exec here would tear down the login session on
# every Hyprland exit, which makes tty1's getty restart in a tight loop
# and permanently die once systemd's start-limit is hit.
#
if [ "$(id -un)" = "slate" ] && [ "$(tty)" = "/dev/tty1" ] &&
    [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
    Hyprland
fi

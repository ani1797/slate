#!/bin/sh
# Auto-start Hyprland on tty1 for the live session's root autologin.
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
# --i-am-really-stupid: Hyprland refuses to start as root by default. The
# live ISO, like upstream archiso's own baseline/releng profiles, only has
# a root account (autologin, single ephemeral session, no other users) —
# there is no non-root user to run it as. This flag is Hyprland's own
# documented opt-out for exactly that single-user/root context; it is not
# a workaround for a bug.
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
    Hyprland --i-am-really-stupid
fi

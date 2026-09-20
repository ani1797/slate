# Checks for slate-desktop: compositor, session, greeter, portals and fonts.

check "Hyprland is installed" have Hyprland
check "XWayland is installed" have Xwayland
check "a Wayland session is advertised" test -f /usr/share/wayland-sessions/hyprland.desktop
check "the desktop portal is installed" test -x /usr/lib/xdg-desktop-portal
check "the Hyprland portal backend is installed" test -x /usr/lib/xdg-desktop-portal-hyprland

# Without a font package no Wayland client can render text at all, which is a
# hard failure rather than a cosmetic one — this was found by boot-testing.
check "the terminal font resolves" sh -c 'fc-match "JetBrainsMono Nerd Font" | grep -qi jetbrains'
check "a fallback font resolves" sh -c 'fc-match sans-serif | grep -qvi "not found"'

check "the audio stack is installed" have pipewire
check "the session manager is installed" have wireplumber

if slate_is_live; then
    # The live session autostarts Hyprland from the autologin shell instead of
    # running a greeter, so there is no greetd to enable.
    skip "greeter is configured" "live session autostarts Hyprland"
    skip "greeter is enabled" "live session autostarts Hyprland"
else
    check "greeter is configured" test -f /etc/greetd/config.toml
    check "greeter points at the Wayland sessions directory" \
        grep -q "/usr/share/wayland-sessions" /etc/greetd/config.toml
    check "greeter is enabled" systemctl is-enabled greetd.service
fi

check "packaged Hyprland defaults are present" \
    test -f /usr/share/slate/config/.config/hypr/hyprland.conf
check "Hyprland configuration is seeded into the user's home" \
    test -f "$SLATE_HOME/.config/hypr/hyprland.conf"

# Checks for slate-launcher: the Vicinae command palette and Slate's defaults.

check "vicinae is installed" have vicinae
check "Slate's theme is installed" test -f /usr/share/vicinae/themes/slate.toml
check "packaged launcher defaults are present" \
    test -f /usr/share/slate/launcher/vicinae-defaults.jsonc
check "the icon theme is installed" test -d /usr/share/icons/Papirus

check "launcher settings are seeded into the user's home" \
    test -f "$SLATE_HOME/.config/vicinae/settings.json"
# Onboarding state is pre-seeded as already-complete so a new user lands straight
# in the launcher rather than the first-run wizard.
check "onboarding is pre-seeded" \
    test -f "$SLATE_HOME/.local/state/vicinae/onboarding.json"

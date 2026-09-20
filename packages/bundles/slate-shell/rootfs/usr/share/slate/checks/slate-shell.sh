# Checks for slate-shell: the terminal and shell environment.

check "ghostty is installed" have ghostty
check "ghostty's terminfo is installed" sh -c 'infocmp -x xterm-ghostty >/dev/null'
check "direnv is installed" have direnv

check "direnv's shell hook is installed system-wide" test -f /etc/profile.d/direnv.sh
# The hook only earns its keep if it actually loads in a real login shell, which
# is what was silently missing on installed systems before. -i is required
# here because the hook is deliberately guarded to interactive shells only
# (see /etc/profile.d/direnv.sh) — a non-interactive `bash -lc` would never
# load it even when correctly installed.
check "direnv's hook loads in a login shell" \
    bash -lic 'declare -F _direnv_hook >/dev/null'

check "packaged ghostty defaults are present" \
    test -f /usr/share/slate/config/.config/ghostty/config
check "ghostty configuration is seeded into the user's home" \
    test -f "$SLATE_HOME/.config/ghostty/config"
check "direnv configuration is seeded into the user's home" \
    test -f "$SLATE_HOME/.config/direnv/direnvrc"

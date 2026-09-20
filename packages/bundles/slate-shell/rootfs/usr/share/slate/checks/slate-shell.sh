# Checks for slate-shell: the terminal and shell environment.

check "ghostty is installed" have ghostty
check "ghostty's terminfo is installed" sh -c 'infocmp -x xterm-ghostty >/dev/null'
check "direnv is installed" have direnv
check "zellij is installed" have zellij
check "zsh is installed" have zsh

check "direnv's shell hook is installed system-wide" test -f /etc/profile.d/direnv.sh
# The hook only earns its keep if it actually loads in a real login shell, which
# is what was silently missing on installed systems before. -i is required
# here because the hook is deliberately guarded to interactive shells only
# (see /etc/profile.d/direnv.sh) — a non-interactive `bash -lc` would never
# load it even when correctly installed.
check "direnv's hook loads in a login shell" \
    env SLATE_NO_ZELLIJ=1 bash -lic 'declare -F _direnv_hook >/dev/null'

check "packaged ghostty defaults are present" \
    test -f /usr/share/slate/config/.config/ghostty/config
check "packaged zellij defaults are present" \
    test -f /usr/share/slate/config/.config/zellij/config.kdl
check "packaged shell launcher is present" \
    test -x /usr/bin/slate-shell
check "zellij configuration parses" \
    env ZELLIJ_CONFIG_FILE=/usr/share/slate/config/.config/zellij/config.kdl \
    zellij setup --check
check "zellij configuration enables session serialization" \
    grep -q '^session_serialization true$' \
    /usr/share/slate/config/.config/zellij/config.kdl
check "zellij profile hook is valid POSIX sh" \
    sh -n /etc/profile.d/slate-zellij.sh
check "ghostty configuration is seeded into the user's home" \
    test -f "$SLATE_HOME/.config/ghostty/config"
check "zellij configuration is seeded into the user's home" \
    test -f "$SLATE_HOME/.config/zellij/config.kdl"
check "zellij serialization is enabled in the user's config" \
    grep -q '^session_serialization true$' \
    "$SLATE_HOME/.config/zellij/config.kdl"
check "direnv configuration is seeded into the user's home" \
    test -f "$SLATE_HOME/.config/direnv/direnvrc"
check "zellij aliases load in bash login shells" \
    env SLATE_NO_ZELLIJ=1 bash -lic 'alias zj >/dev/null'
check "zellij aliases load in zsh login shells" \
    env SLATE_NO_ZELLIJ=1 zsh -lic 'alias zj >/dev/null'
check "zellij can create a detached session" \
    as_user sh -c 'name=slate-doctor-$$; zellij attach --create-background "$name" >/dev/null 2>&1 && zellij list-sessions --short | grep -qx "$name" && zellij kill-session "$name" >/dev/null 2>&1'

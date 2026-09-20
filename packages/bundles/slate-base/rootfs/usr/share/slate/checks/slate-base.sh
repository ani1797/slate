# Checks for slate-base: the plumbing every Slate system depends on.

check "slate-doctor is installed" test -x /usr/bin/slate-doctor
check "slate-refresh-config is installed" test -x /usr/bin/slate-refresh-config
check "packaged pacman.conf is present" test -f /usr/share/slate/pacman.conf

# Reads the fingerprint from the shipped keyring rather than hardcoding it
# here, so a future key rotation (which touches the keyring package, not this
# script) can't silently desync from what this check actually verifies.
_slate_signing_fpr=$(gpg --no-default-keyring \
    --keyring /usr/share/pacman/keyrings/slate.gpg \
    --with-colons --list-keys --fingerprint 2>/dev/null \
    | awk -F: '$1 == "fpr" { print $10; exit }')
check "slate-keyring is installed" test -n "$_slate_signing_fpr"
check "slate's signing key is in the pacman keyring" \
    pacman-key --list-keys "$_slate_signing_fpr"

if slate_is_live; then
    # The live ISO runs from read-only media and is never "installed", so
    # first-boot provisioning is neither expected nor meaningful there.
    skip "first-boot provisioning ran" "live session"
    skip "pacman.conf has no dangling file:// repository" "live session"
else
    check "first-boot provisioning ran" test -e /var/lib/slate/first-boot-done

    # The specific failure this guards against: archinstall appends its
    # custom_repositories entry to the target's pacman.conf, leaving a file://
    # server behind that only ever existed on the install media. The first
    # `pacman -Syu` after reboot fails on it.
    check_not "pacman.conf has no dangling file:// repository" \
        grep -qE '^[[:space:]]*Server[[:space:]]*=[[:space:]]*file://' /etc/pacman.conf

    # Proves first-boot delivered the real, published [slate] repo, not just
    # that the dangling install-media entry is gone.
    check "pacman.conf has the published [slate] repository" \
        grep -qE '^\[slate\]$' /etc/pacman.conf
fi

if is_root; then
    check "pacman database can be synchronised" pacman -Sy --noconfirm
else
    skip "pacman database can be synchronised" "needs root"
fi

# -Qi (local database), not -Si (sync database): the sync database is only
# populated after a `pacman -Sy`, which needs root and is checked separately
# above. Querying the already-installed bash package needs neither.
check "package metadata is readable" pacman -Qi bash

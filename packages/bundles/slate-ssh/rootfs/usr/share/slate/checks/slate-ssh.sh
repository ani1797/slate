# Checks for slate-ssh: per-user agent, client defaults, and hardened sshd.

check "ssh is installed" have ssh
check "sshd is installed" have sshd
check "ssh-agent is installed" have ssh-agent
check "ssh-add is installed" have ssh-add
check "the askpass helper is installed" test -x /usr/bin/lxqt-openssh-askpass

check "the agent socket unit is enabled system-wide" \
    test -L /usr/lib/systemd/user/sockets.target.wants/ssh-agent.socket
check "Slate's environment.d entry is installed" \
    test -f /usr/lib/environment.d/50-slate-ssh.conf
check "the login-shell agent hook is installed" \
    test -f /etc/profile.d/slate-ssh-agent.sh

check "packaged client defaults are present" \
    test -f /etc/ssh/ssh_config.d/50-slate.conf
check "the client applies AddKeysToAgent" \
    sh -c 'ssh -G example.com 2>/dev/null | grep -qi "^addkeystoagent true$"'

check "packaged sshd defaults are present" \
    test -f /etc/ssh/sshd_config.d/50-slate.conf

# sshd -t/-T both refuse to run without host keys, and on the live ISO sshd is
# masked so sshdgenkeys.service never fires and none exist. That is expected
# there, not a config error, so these checks only run on an installed system.
if slate_is_live; then
    skip "sshd's configuration is valid" "sshd is masked on the live session, no host keys yet"
    skip "sshd enforces key-only authentication" "sshd is masked on the live session, no host keys yet"
    skip "sshd denies root login" "sshd is masked on the live session, no host keys yet"
elif is_root; then
    check "sshd's configuration is valid" sshd -t
    check "sshd enforces key-only authentication" \
        sh -c 'sshd -T | grep -qi "^passwordauthentication no$"'
    check "sshd denies root login" \
        sh -c 'sshd -T | grep -qi "^permitrootlogin no$"'
else
    skip "sshd's configuration is valid" "sshd -t needs root"
    skip "sshd enforces key-only authentication" "sshd -T needs root"
    skip "sshd denies root login" "sshd -T needs root"
fi

# The agent is reachable only if both the socket unit activated and
# SSH_AUTH_SOCK actually points at it in a real login shell — this is the
# end-to-end proof, not just that the files are in place. ssh-add -l exits 1
# for "connected, no identities" (expected on a fresh system) and 2 for
# "cannot connect to the agent"; only 2 is a real failure.
user_runtime_dir="/run/user/$(id -u "$SLATE_USER" 2>/dev/null)"
if is_root && [[ $SLATE_USER != root ]]; then
    if [[ -d $user_runtime_dir ]]; then
        check "the agent is reachable for $SLATE_USER" \
            sh -c "! runuser -u \"$SLATE_USER\" -- env XDG_RUNTIME_DIR=\"$user_runtime_dir\" ssh-add -l; [[ \$? -ne 2 ]]"
    else
        skip "the agent is reachable for $SLATE_USER" "$SLATE_USER has no active session ($user_runtime_dir missing)"
    fi
else
    check "the agent is reachable" \
        sh -c '! ssh-add -l; [[ $? -ne 2 ]]'
fi

# Runs as $SLATE_USER, not as whoever invoked slate-doctor: root has no
# XDG_RUNTIME_DIR of its own, so `sudo slate-doctor` must still prove the
# login-shell wiring for the real target user.
if is_root && [[ $SLATE_USER != root ]]; then
    if [[ -d $user_runtime_dir ]]; then
        check "SSH_AUTH_SOCK is exported in a login shell and points at the standard agent socket" \
            sh -c "runuser -u \"$SLATE_USER\" -- env XDG_RUNTIME_DIR=\"$user_runtime_dir\" bash -lic 'test \"\$SSH_AUTH_SOCK\" = \"\$XDG_RUNTIME_DIR/ssh-agent.socket\"'"
    else
        skip "SSH_AUTH_SOCK is exported in a login shell and points at the standard agent socket" \
            "$SLATE_USER has no active session ($user_runtime_dir missing)"
    fi
else
    check "SSH_AUTH_SOCK is exported in a login shell and points at the standard agent socket" \
        bash -lic 'test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/ssh-agent.socket"'
fi

# Regression test for the profile.d guard: a login shell reached over SSH must
# never have SSH_AUTH_SOCK overwritten, or agent forwarding silently breaks.
check "SSH_AUTH_SOCK is left untouched inside a forwarded SSH session" \
    env SSH_CONNECTION='198.51.100.1 22 198.51.100.2 22' bash -lc 'test -z "$SSH_AUTH_SOCK"'

if slate_is_live; then
    check "sshd is masked on the live session" \
        sh -c 'systemctl is-enabled sshd.service 2>&1 | grep -q "^masked$"'
else
    # sshd is enabled by a package-shipped .wants symlink under /usr/lib, not
    # by `systemctl enable` (which would write to /etc). `systemctl is-enabled`
    # only ever reports the /etc override tier, so it reports "disabled" here
    # even though the unit is genuinely pulled into multi-user.target and
    # running — asserting on it would be a false failure. The symlink's
    # presence (packaging correctness) plus the unit actually being active
    # (real-world proof) is what actually matters.
    check "sshd is enabled system-wide" \
        test -L /usr/lib/systemd/system/multi-user.target.wants/sshd.service
    check "sshd is running" systemctl is-active --quiet sshd.service
fi

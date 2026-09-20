#!/bin/sh
# Point login shells at the per-user ssh-agent socket. environment.d (see
# 50-slate-ssh.conf) covers the systemd user manager and graphical session, but
# not TTY logins or a login shell reached over SSH, so this fills that gap.
#
# Guard follows the Arch Wiki's documented rule (SSH_keys § "Start ssh-agent
# with systemd user"): never set SSH_AUTH_SOCK inside an SSH session, or a
# forwarded agent (ssh -A / ForwardAgent yes) gets silently overwritten and
# forwarding breaks. SSH_CONNECTION is only ever set by sshd, so its absence is
# what actually identifies a non-SSH session; the SSH_AUTH_SOCK check alone
# would not, since a plain (non-forwarded) SSH login leaves it unset too.
if [ -z "$SSH_CONNECTION" ] && [ -z "$SSH_AUTH_SOCK" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
    SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
    export SSH_AUTH_SOCK
fi

# SSH_ASKPASS_REQUIRE is deliberately left unset (OpenSSH's default: used only
# when there is no controlling TTY). lxqt-openssh-askpass also needs DISPLAY or
# WAYLAND_DISPLAY to run at all, so forcing it here would break exactly the
# headless and SSH-in sessions that have neither.
if [ -x /usr/bin/lxqt-openssh-askpass ]; then
    export SSH_ASKPASS=/usr/bin/lxqt-openssh-askpass
fi

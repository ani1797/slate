#!/bin/sh
# Slate's interactive terminal policy.
#
# This file is POSIX sh because zsh's /etc/zsh/zprofile sources /etc/profile
# under `emulate sh`. It therefore configures both bash and zsh without owning
# either shell's package-managed rc file.

case $- in
    *i*) ;;
    *) return 0 2>/dev/null || exit 0 ;;
esac

alias zj='zellij attach --create main'
alias zjs='zellij list-sessions'
alias zja='zellij attach'
alias zjk='zellij kill-session'
alias zjbg='zellij attach --create-background'
alias zjrun='zellij run --session'

if [ -n "${ZELLIJ-}" ] || [ -n "${SLATE_NO_ZELLIJ-}" ] || [ "${TERM-}" != xterm-ghostty ]; then
    return 0 2>/dev/null || exit 0
fi

exec zellij attach --create main

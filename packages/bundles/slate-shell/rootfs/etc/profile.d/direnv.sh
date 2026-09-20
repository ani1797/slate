#!/bin/sh
# Hook direnv into interactive bash logins system-wide.
#
# Guarded to interactive shells only (same pattern as hyprland-autostart.sh):
# direnv's hook re-exports the environment on every prompt, which is only
# meaningful — and safe — for an interactive session, not for script/login
# non-interactive invocations of bash.
case $- in
    *i*)
        eval "$(direnv hook bash)"
        ;;
esac

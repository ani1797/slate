# Checks for slate-capture: screenshots and screen recording.

check "slate-capture is installed" test -x /usr/bin/slate-capture
check "slate-capture parses as valid shell" bash -n /usr/bin/slate-capture

for tool in grim slurp wf-recorder swappy wl-copy mako notify-send jq; do
    check "$tool is installed" have "$tool"
done

check "notification daemon configuration is seeded" \
    test -f "$SLATE_HOME/.config/mako/config"

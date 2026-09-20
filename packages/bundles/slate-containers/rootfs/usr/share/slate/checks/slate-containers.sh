# Checks for slate-containers: rootless podman.

check "podman is installed" have podman
check "podman-compose is installed" have podman-compose
check "the docker compatibility wrapper is installed" have docker
check "the network stack is installed" test -x /usr/lib/podman/netavark
check "container DNS is installed" test -x /usr/lib/podman/aardvark-dns

check "Slate's registry search policy is installed" \
    test -f /etc/containers/registries.conf.d/50-slate.conf
check "the storage driver default is installed" \
    test -f /usr/share/containers/storage.conf.d/50-slate.conf

# Rootless is the whole point: podman running only as root would mean the
# subordinate id ranges never got provisioned.
check "subordinate uid range is allocated for $SLATE_USER" \
    grep -q "^${SLATE_USER}:" /etc/subuid
check "subordinate gid range is allocated for $SLATE_USER" \
    grep -q "^${SLATE_USER}:" /etc/subgid

if is_root && [[ $SLATE_USER != root ]]; then
    check "podman works rootless" as_user podman info
else
    check "podman works rootless" podman info
fi

check "the unqualified search registry is in effect" \
    sh -c 'podman info --format "{{.Registries}}" 2>/dev/null | grep -q docker.io'

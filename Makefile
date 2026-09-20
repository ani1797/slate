PROFILE  := archiso
WORK_DIR := work
OUT_DIR  := out
PACKAGE_DIR := packages
PACKAGE_WORK_DIR := .build
PACKAGE_BUILD_DIR := $(abspath $(PACKAGE_WORK_DIR)/makepkg)
PACKAGE_SOURCE_DIR := $(abspath $(PACKAGE_WORK_DIR)/sources)
REPO_DIR := $(abspath $(PACKAGE_WORK_DIR)/repo)
PACMAN_CONF := $(abspath $(PACKAGE_WORK_DIR)/pacman.conf)
# Staged copy of REPO_DIR baked into the ISO itself so the local repo is
# reachable by archinstall's pacstrap when installing to disk, not just during
# the build. /var/cache is the FHS home for a local package mirror; /opt is for
# self-contained third-party software, which this is not.
STAGED_REPO_DIR := $(PROFILE)/airootfs/var/cache/slate/repo
# Every directory under packages/ containing a PKGBUILD is built automatically,
# at any tier depth (meta/, bundles/, vendor/) — no manual list to keep in sync.
# Built in tier order (vendor, bundles, meta), not plain alphabetical: that is
# also the dependency direction (vendor packages carry no Slate-internal
# depends=; a bundle may depend on a vendor package, e.g. slate-base on
# slate-keyring; meta depends= every bundle). This matters once
# MAKEPKG_DEPS_FLAG=--syncdeps (CI) needs an earlier-built package's own repo
# entry to already exist to satisfy a later package's depends=.
PACKAGE_DIRS := $(shell for tier in vendor bundles meta; do find $(PACKAGE_DIR)/$$tier -mindepth 1 -name PKGBUILD -printf '%h\n' 2>/dev/null | sort; done)
# --nodeps by default: a developer's own machine already carries the tools
# these packages build with, and `packages` must never reach for pacman to
# install things onto it as a side effect. CI runs in a disposable container
# with nothing preinstalled, so it overrides this to --syncdeps (see
# .github/workflows/publish-repo.yml), which lets makepkg install missing
# depends/makedepends itself instead of failing on a bare "command not found".
MAKEPKG_DEPS_FLAG ?= --nodeps
# Empty by default: a local checkout has no access to the signing key (it
# lives only as a GitHub Actions secret), so `make package-repo`/`make build`
# stay unsigned for local iteration — exactly as before signing existed. CI
# sets both of these to --sign once it has imported the key; see
# .github/workflows/publish-repo.yml.
MAKEPKG_SIGN_FLAG ?=
REPO_ADD_SIGN_FLAG ?=

VM_DIR := .vm
VM_VARS := $(VM_DIR)/OVMF_VARS.fd
VM_DISK := $(VM_DIR)/slate.qcow2
VM_DISK_SIZE := 40G
VM_PIDFILE := $(VM_DIR)/qemu.pid
VM_LOG := $(VM_DIR)/qemu.log
VM_SERIAL := $(VM_DIR)/serial.log
OVMF_CODE := /usr/share/edk2-ovmf/x64/OVMF_CODE.4m.fd
OVMF_VARS_TEMPLATE := /usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd

.PHONY: build packages package-repo check-packages evict-stale-cache clean-iso clean \
        vm-live vm-disk vm-reset vm-stop start stop

build: package-repo
	@$(MAKE) --no-print-directory clean-iso
	@rm -rf -- "$(STAGED_REPO_DIR)"
	@mkdir -p "$(STAGED_REPO_DIR)"
	@cp -a -- "$(REPO_DIR)"/. "$(STAGED_REPO_DIR)"/
	@$(MAKE) --no-print-directory evict-stale-cache
	sudo mkarchiso -v -C "$(PACMAN_CONF)" -w "$(WORK_DIR)" -o "$(OUT_DIR)" "$(PROFILE)"

# Rebuilding a package without bumping pkgrel produces a different file under an
# identical name. pacman's shared host cache matches on that name, so it happily
# serves the previous build and then fails the whole transaction with "invalid or
# corrupted package (checksum)" - which reads like a build problem but is not.
#
# Evicting only Slate's own packages keeps official packages cached, so builds
# stay fast, while making iteration on a package immune to this entirely.
evict-stale-cache:
	@set -eu; \
	cache=/var/cache/pacman/pkg; \
	[ -d "$$cache" ] || exit 0; \
	stale=""; \
	for pkg in "$(REPO_DIR)"/*.pkg.tar.*; do \
		cached="$$cache/$$(basename "$$pkg")"; \
		if [ -f "$$cached" ] && ! cmp -s "$$pkg" "$$cached"; then \
			stale="$$stale $$cached"; \
		fi; \
	done; \
	if [ -n "$$stale" ]; then \
		for f in $$stale; do printf 'Evicting stale cached build: %s\n' "$$f"; done; \
		sudo rm -f -- $$stale; \
	fi

# Two directories declaring the same pkgname would silently clobber each other
# in the repo, with the winner decided by build order. Fail loudly instead.
check-packages:
	@set -eu; \
	dupes="$$(for dir in $(PACKAGE_DIRS); do \
		awk -F= '/^pkgname=/ { gsub(/[()'"'"'"]/, "", $$2); print $$2; exit }' "$$dir/PKGBUILD"; \
	done | sort | uniq -d)"; \
	if [ -n "$$dupes" ]; then \
		printf 'Duplicate pkgname(s) across package directories:\n%s\n' "$$dupes" >&2; \
		exit 1; \
	fi

packages: check-packages
	@rm -rf -- "$(PACKAGE_BUILD_DIR)" "$(REPO_DIR)"
	@mkdir -p "$(PACKAGE_BUILD_DIR)" "$(PACKAGE_SOURCE_DIR)" "$(REPO_DIR)"
	@set -eu; \
	for dir in $(PACKAGE_DIRS); do \
		PKGDEST="$(REPO_DIR)" \
		SRCDEST="$(PACKAGE_SOURCE_DIR)" \
		BUILDDIR="$(PACKAGE_BUILD_DIR)" \
		makepkg --dir "$$dir" \
			--cleanbuild --clean --force $(MAKEPKG_DEPS_FLAG) $(MAKEPKG_SIGN_FLAG) --noconfirm; \
		if [ "$(MAKEPKG_DEPS_FLAG)" = "--syncdeps" ]; then \
			repo-add --quiet $(REPO_ADD_SIGN_FLAG) "$(REPO_DIR)/slate.db.tar.gz" "$(REPO_DIR)"/*.pkg.tar.zst; \
			sudo pacman -Sy --noconfirm; \
		fi; \
	done

package-repo: packages
	@repo-add --quiet $(REPO_ADD_SIGN_FLAG) "$(REPO_DIR)/slate.db.tar.gz" "$(REPO_DIR)"/*.pkg.tar.zst
	@mkdir -p "$(dir $(PACMAN_CONF))"
	@awk -v repo="$(REPO_DIR)" '\
		/^\[options\]$$/ { print; print "DisableSandbox"; next } \
		/^\[core\]$$/ && !added { \
			print "[slate]"; \
			print "SigLevel = Never"; \
			print "Server = file://" repo; \
			print ""; \
			added = 1; \
		} \
		{ print }' "$(PROFILE)/pacman.conf" > "$(PACMAN_CONF)"

clean-iso:
	@work_dir="$(abspath $(WORK_DIR))"; \
	awk -v prefix="$$work_dir/" '$$5 ~ ("^" prefix) { print $$5 }' /proc/self/mountinfo | \
		sort -r | \
		while IFS= read -r mountpoint; do \
			case "$$mountpoint" in \
				"$$work_dir"/*) sudo umount -- "$$mountpoint" ;; \
				*) printf 'Refusing to unmount path outside %s: %s\n' "$$work_dir" "$$mountpoint" >&2; exit 1 ;; \
			esac; \
		done && \
	sudo rm -rf -- "$(WORK_DIR)" "$(OUT_DIR)"

clean: clean-iso
	@rm -rf -- "$(PACKAGE_WORK_DIR)" "$(STAGED_REPO_DIR)"

# Shared QEMU launch. $$EXTRA carries the per-target boot media arguments.
# A persistent qcow2 is always attached: without one an install-to-disk test is
# impossible, which is the single most important thing to be able to verify.
#
# -vga std, not virtio: virtio-vga's virgl path segfaults QEMU under -display
# vnc on at least one build host. std is the portable choice and is plenty for
# verifying a Wayland session actually comes up.
define VM_LAUNCH
mkdir -p "$(VM_DIR)"; \
[ -f "$(VM_VARS)" ] || cp "$(OVMF_VARS_TEMPLATE)" "$(VM_VARS)"; \
[ -f "$(VM_DISK)" ] || qemu-img create -f qcow2 "$(VM_DISK)" $(VM_DISK_SIZE) >/dev/null; \
if [ -f "$(VM_PIDFILE)" ] && kill -0 "$$(cat $(VM_PIDFILE))" 2>/dev/null; then \
	echo "VM already running (pid $$(cat $(VM_PIDFILE)))." >&2; \
	exit 1; \
fi; \
echo "Connect a VNC viewer to localhost:5900 to view the display."; \
echo "Serial console is captured to $(VM_SERIAL)."; \
setsid qemu-system-x86_64 \
	-enable-kvm -m 4G -smp 4 \
	-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
	-drive if=pflash,format=raw,file="$(VM_VARS)" \
	-drive file="$(abspath $(VM_DISK))",format=qcow2,if=virtio \
	-vga std \
	-display vnc=localhost:0 \
	-serial file:"$(abspath $(VM_SERIAL))" \
	-name "Slate" \
	-pidfile "$(abspath $(VM_PIDFILE))" \
	$$EXTRA \
	</dev/null >"$(VM_LOG)" 2>&1 &
endef

# Boot the live ISO with the persistent disk attached. Installing to disk is
# done from inside this session:
#   sudo archinstall --config /root/archinstall/config.json
vm-live:
	@set -eu; \
	iso="$$(ls -t $(OUT_DIR)/*.iso 2>/dev/null | head -n1)"; \
	if [ -z "$$iso" ]; then \
		echo "No ISO found in $(OUT_DIR); run 'make build' first." >&2; \
		exit 1; \
	fi; \
	echo "Starting Slate live VM from $$iso ..."; \
	EXTRA="-cdrom $$iso -boot d"; \
	$(VM_LAUNCH)

# Boot the installed system with NO ISO attached. This is the only way to prove
# the installed system stands on its own rather than leaning on live media.
vm-disk:
	@set -eu; \
	if [ ! -f "$(VM_DISK)" ]; then \
		echo "No VM disk at $(VM_DISK); run 'make vm-live' and install first." >&2; \
		exit 1; \
	fi; \
	echo "Booting installed Slate system from $(VM_DISK) (no ISO attached) ..."; \
	EXTRA="-boot c"; \
	$(VM_LAUNCH)

vm-reset: vm-stop
	@rm -f -- "$(VM_DISK)" "$(VM_VARS)" "$(VM_SERIAL)" "$(VM_LOG)"
	@echo "Discarded VM disk and firmware variables."

vm-stop:
	@if [ -f "$(VM_PIDFILE)" ] && kill -0 "$$(cat $(VM_PIDFILE))" 2>/dev/null; then \
		kill "$$(cat $(VM_PIDFILE))"; \
		rm -f "$(VM_PIDFILE)"; \
		echo "Stopped Slate VM."; \
	else \
		echo "No running Slate VM found."; \
	fi

start: vm-live
stop: vm-stop

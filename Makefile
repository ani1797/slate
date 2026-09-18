PROFILE := archiso/slate
BUILD_DIR := .build
BUILD_PROFILE := $(abspath $(BUILD_DIR)/profile)
WORK_DIR := work
OUT_DIR := out
PACKAGE_DIR := packages
PACKAGE_BUILD_ROOT := $(abspath $(BUILD_DIR)/chroot/root)
PACKAGE_SOURCE_DIR := $(abspath $(BUILD_DIR)/sources)
REPO_DIR := $(abspath $(BUILD_DIR)/repo)
PACMAN_CONF := $(abspath $(BUILD_DIR)/pacman.conf)
KEYRING_DIR := $(abspath $(BUILD_DIR)/pacman-keyring)
SIGNING_KEYRING := $(abspath $(BUILD_DIR)/slate.gpg)
SIGNING_KEY ?=

# Build order matters only for custom package dependencies. All other package
# directories are included automatically after these entries.
PACKAGE_ORDER := vicinae-bin slate-launcher slate-capture paru-bin
CUSTOM_PACKAGES := $(sort $(patsubst $(PACKAGE_DIR)/%/PKGBUILD,%,$(wildcard $(PACKAGE_DIR)/*/PKGBUILD)))
UNORDERED_PACKAGES := $(filter-out $(PACKAGE_ORDER),$(CUSTOM_PACKAGES))
PACKAGES_TO_BUILD := $(PACKAGE_ORDER) $(UNORDERED_PACKAGES)

VM_DIR := .vm
VM_VARS := $(VM_DIR)/OVMF_VARS.fd
VM_PIDFILE := $(VM_DIR)/qemu.pid
VM_LOG := $(VM_DIR)/qemu.log
OVMF_CODE := /usr/share/edk2-ovmf/x64/OVMF_CODE.4m.fd
OVMF_VARS_TEMPLATE := /usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd

.PHONY: build packages package-repo clean-iso clean start stop

build: package-repo
	@$(MAKE) --no-print-directory clean-iso
	sudo mkarchiso -v -C "$(PACMAN_CONF)" -w "$(WORK_DIR)" -o "$(OUT_DIR)" "$(BUILD_PROFILE)"

packages:
	@test -n "$(SIGNING_KEY)" || { echo "SIGNING_KEY must name a local GPG signing key" >&2; exit 2; }
	@command -v mkarchroot >/dev/null
	@command -v makechrootpkg >/dev/null
	@rm -rf -- "$(PACKAGE_BUILD_ROOT)" "$(REPO_DIR)" "$(PACKAGE_SOURCE_DIR)"
	@mkdir -p "$(REPO_DIR)" "$(PACKAGE_SOURCE_DIR)"
	@rm -rf -- "$(KEYRING_DIR)" "$(SIGNING_KEYRING)"
	@gpg --batch --export "$(SIGNING_KEY)" > "$(SIGNING_KEYRING)"
	@test -s "$(SIGNING_KEYRING)" || { echo "SIGNING_KEY does not identify an exportable public key" >&2; exit 2; }
	@pacman-key --gpgdir "$(KEYRING_DIR)" --init
	@pacman-key --gpgdir "$(KEYRING_DIR)" --add "$(SIGNING_KEYRING)"
	@pacman-key --gpgdir "$(KEYRING_DIR)" --lsign-key "$(SIGNING_KEY)"
	@awk -v repo="$(REPO_DIR)" -v keyring="$(KEYRING_DIR)" '\
		/^\[options\]$$/ { print; print "GPGDir = " keyring; next } \
		/^\[core\]$$/ && !added { \
			print "[slate]"; print "SigLevel = Required DatabaseRequired"; \
			print "Server = file://" repo; print ""; added = 1 \
		} { print }' "$(PROFILE)/pacman.conf" > "$(PACMAN_CONF)"
	sudo mkarchroot -C "$(PROFILE)/pacman.conf" "$(PACKAGE_BUILD_ROOT)" base-devel
	@set -eu; \
	for package in $(PACKAGES_TO_BUILD); do \
		cd "$(abspath $(PACKAGE_DIR)/$$package)"; \
		PKGDEST="$(REPO_DIR)" SRCDEST="$(PACKAGE_SOURCE_DIR)" \
			makechrootpkg -r "$(PACKAGE_BUILD_ROOT)" -c -n; \
		find "$(REPO_DIR)" -maxdepth 1 -type f -name "*.pkg.tar.*" ! -name "*.sig" \
			-exec gpg --batch --yes --local-user "$(SIGNING_KEY)" --detach-sign {} +; \
		repo-add --sign --key "$(SIGNING_KEY)" --quiet \
			"$(REPO_DIR)/slate.db.tar.gz" $$(find "$(REPO_DIR)" -maxdepth 1 -type f -name "*.pkg.tar.*" ! -name "*.sig" -print); \
	done

package-repo: packages
	@rm -rf -- "$(BUILD_PROFILE)"
	@mkdir -p "$(BUILD_PROFILE)"
	@cp -a "$(PROFILE)/." "$(BUILD_PROFILE)/"
	@cat "$(BUILD_PROFILE)/airootfs/usr/share/slate/installer/packages.shared.x86_64" \
		"$(BUILD_PROFILE)/airootfs/usr/share/slate/installer/packages.live.x86_64" \
		> "$(BUILD_PROFILE)/packages.x86_64"
	@mkdir -p "$(BUILD_PROFILE)/airootfs/usr/share/slate/repo" \
		"$(BUILD_PROFILE)/airootfs/usr/share/pacman/keyrings"
	@cp -a "$(REPO_DIR)/." "$(BUILD_PROFILE)/airootfs/usr/share/slate/repo/"
	@install -m 0644 "$(SIGNING_KEYRING)" \
		"$(BUILD_PROFILE)/airootfs/usr/share/pacman/keyrings/slate.gpg"

clean-iso:
	@work_dir="$(abspath $(WORK_DIR))"; \
	awk -v prefix="$$work_dir/" '$$5 ~ ("^" prefix) { print $$5 }' /proc/self/mountinfo | \
		sort -r | while IFS= read -r mountpoint; do \
			case "$$mountpoint" in \
				"$$work_dir"/*) sudo umount -- "$$mountpoint" ;; \
				*) printf 'Refusing to unmount path outside %s: %s\n' "$$work_dir" "$$mountpoint" >&2; exit 1 ;; \
			esac; \
		done && sudo rm -rf -- "$(WORK_DIR)" "$(OUT_DIR)"

clean: clean-iso
	@rm -rf -- "$(BUILD_DIR)"

start:
	@iso="$$(ls -t $(OUT_DIR)/*.iso 2>/dev/null | head -n1)"; \
	if [ -z "$$iso" ]; then echo "No ISO found in $(OUT_DIR); run 'make build' first." >&2; exit 1; fi; \
	if [ -f "$(VM_PIDFILE)" ] && kill -0 "$$(cat $(VM_PIDFILE))" 2>/dev/null; then echo "VM already running (pid $$(cat $(VM_PIDFILE)))." >&2; exit 1; fi; \
	mkdir -p "$(VM_DIR)"; [ -f "$(VM_VARS)" ] || cp "$(OVMF_VARS_TEMPLATE)" "$(VM_VARS)"; \
	echo "Starting Slate VM from $$iso ..."; echo "Connect a VNC viewer to localhost:5900 to view the display."; \
	setsid qemu-system-x86_64 -enable-kvm -m 4G -smp 4 \
		-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
		-drive if=pflash,format=raw,file="$(VM_VARS)" -cdrom "$$iso" -boot d \
		-vga virtio -display vnc=localhost:0 -name "Slate Live" \
		-pidfile "$(abspath $(VM_PIDFILE))" </dev/null >"$(VM_LOG)" 2>&1 &

stop:
	@if [ -f "$(VM_PIDFILE)" ] && kill -0 "$$(cat $(VM_PIDFILE))" 2>/dev/null; then \
		kill "$$(cat $(VM_PIDFILE))"; rm -f "$(VM_PIDFILE)"; echo "Stopped Slate VM."; \
	else echo "No running Slate VM found."; fi

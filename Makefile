PROFILE  := archiso/slate
WORK_DIR := work
OUT_DIR  := out
PACKAGE_DIR := packages
PACKAGE_WORK_DIR := .build
PACKAGE_BUILD_DIR := $(abspath $(PACKAGE_WORK_DIR)/makepkg)
PACKAGE_SOURCE_DIR := $(abspath $(PACKAGE_WORK_DIR)/sources)
REPO_DIR := $(abspath $(PACKAGE_WORK_DIR)/repo)
PACMAN_CONF := $(abspath $(PACKAGE_WORK_DIR)/pacman.conf)
CUSTOM_PACKAGES := vicinae-bin slate-launcher

VM_DIR := .vm
VM_VARS := $(VM_DIR)/OVMF_VARS.fd
VM_PIDFILE := $(VM_DIR)/qemu.pid
VM_LOG := $(VM_DIR)/qemu.log
OVMF_CODE := /usr/share/edk2-ovmf/x64/OVMF_CODE.4m.fd
OVMF_VARS_TEMPLATE := /usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd

.PHONY: build packages package-repo clean-iso clean start stop

build: package-repo
	@$(MAKE) --no-print-directory clean-iso
	sudo mkarchiso -v -C "$(PACMAN_CONF)" -w "$(WORK_DIR)" -o "$(OUT_DIR)" "$(PROFILE)"

packages:
	@rm -rf -- "$(PACKAGE_BUILD_DIR)" "$(REPO_DIR)"
	@mkdir -p "$(PACKAGE_BUILD_DIR)" "$(PACKAGE_SOURCE_DIR)" "$(REPO_DIR)"
	@set -eu; \
	for package in $(CUSTOM_PACKAGES); do \
		PKGDEST="$(REPO_DIR)" \
		SRCDEST="$(PACKAGE_SOURCE_DIR)" \
		BUILDDIR="$(PACKAGE_BUILD_DIR)" \
		makepkg --dir "$(PACKAGE_DIR)/$$package" \
			--cleanbuild --clean --force --nodeps --noconfirm; \
	done

package-repo: packages
	@repo-add --quiet "$(REPO_DIR)/slate.db.tar.gz" "$(REPO_DIR)"/*.pkg.tar.*
	@mkdir -p "$(dir $(PACMAN_CONF))"
	@awk -v repo="$(REPO_DIR)" '\
		/^\[options\]$$/ { print; print "DisableSandbox"; next } \
		/^\[core\]$$/ && !added { \
			print "[slate]"; \
			print "SigLevel = Optional TrustAll"; \
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
	@rm -rf -- "$(PACKAGE_WORK_DIR)"

start:
	@iso="$$(ls -t $(OUT_DIR)/*.iso 2>/dev/null | head -n1)"; \
	if [ -z "$$iso" ]; then \
		echo "No ISO found in $(OUT_DIR); run 'make build' first." >&2; \
		exit 1; \
	fi; \
	if [ -f "$(VM_PIDFILE)" ] && kill -0 "$$(cat $(VM_PIDFILE))" 2>/dev/null; then \
		echo "VM already running (pid $$(cat $(VM_PIDFILE)))." >&2; \
		exit 1; \
	fi; \
	mkdir -p "$(VM_DIR)"; \
	[ -f "$(VM_VARS)" ] || cp "$(OVMF_VARS_TEMPLATE)" "$(VM_VARS)"; \
	echo "Starting Slate VM from $$iso ..."; \
	echo "Connect a VNC viewer to localhost:5900 to view the display."; \
	setsid qemu-system-x86_64 \
		-enable-kvm -m 4G -smp 4 \
		-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
		-drive if=pflash,format=raw,file="$(VM_VARS)" \
		-cdrom "$$iso" \
		-boot d \
		-vga virtio \
		-display vnc=localhost:0 \
		-name "Slate Live" \
		-pidfile "$(abspath $(VM_PIDFILE))" \
		</dev/null >"$(VM_LOG)" 2>&1 &

stop:
	@if [ -f "$(VM_PIDFILE)" ] && kill -0 "$$(cat $(VM_PIDFILE))" 2>/dev/null; then \
		kill "$$(cat $(VM_PIDFILE))"; \
		rm -f "$(VM_PIDFILE)"; \
		echo "Stopped Slate VM."; \
	else \
		echo "No running Slate VM found."; \
	fi

#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="slate"
iso_label="SLATE_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Slate"
iso_application="Slate live/install image"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_type="erofs"
airootfs_image_tool_options=('-zlzma,109' -E 'ztailpacking')
bootstrap_tarball_compression=(xz -9e)
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/subgid"]="0:0:644"
  ["/etc/subuid"]="0:0:644"
  ["/etc/sudoers.d/slate"]="0:0:440"
)

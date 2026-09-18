# Installing Slate to disk

Boot the live ISO and run:

```sh
sudo archinstall --config /root/archinstall/config.json
```

This drives Slate's own opinionated package set (Hyprland + greetd/tuigreet,
ghostty, vicinae, slate-shell, slate-launcher, slate-capture, paru, the
podman stack, dev runtimes) through archinstall's guided flow. Anything
genuinely machine/user-specific — disk layout, hostname, locale, bootloader,
username/password — is deliberately **not** in `config.json`; archinstall
prompts for those interactively.

## Audio

`audio_config.audio` is set to `"pipewire"`, which makes archinstall install
`pipewire`, `pipewire-pulse`, `wireplumber`, and friends itself — they are
deliberately **not** repeated in `config.json`'s `packages` list to avoid two
sources of truth drifting apart.

## How the custom packages resolve

`slate-shell`, `vicinae-bin`, `slate-launcher`, `slate-capture`, and `paru`
only exist in Slate's own locally-built pacman repo, not in
`[core]`/`[extra]`. The `Makefile`'s `build` target stages that built repo
into `/opt/slate-repo` inside the ISO itself (see `.gitignore`), and
`config.json`'s `mirror_config.custom_repositories` registers it so
`archinstall`'s pacstrap can resolve those packages when installing to disk
— the same way it resolves official packages.

## Default dotfiles and `/etc/skel`

Hyprland/ghostty/direnv (`slate-shell`), Vicinae (`slate-launcher`), and
mako (`slate-capture`) all ship their default config under
`/etc/skel/...` as part of their package payload — not as raw profile
files — specifically so pacstrap installs them to the target's `/etc/skel`
just like any other package file. archinstall creates the target user
account (copying `/etc/skel` into their home) *before* installing
`config.json`'s `packages` list, so a final `custom_commands` step backfills
anything `/etc/skel` gained afterward into every already-created user's
home (`cp -rn` + `chown`, skipping files that already exist).

## Greeter

`custom_commands` writes `/etc/greetd/config.toml` pointing tuigreet at
`/usr/share/wayland-sessions` (which the `hyprland` package already ships
`hyprland.desktop`/`hyprland-uwsm.desktop` into), and `services` enables
`greetd`. No custom session wrapper script is needed.

## Networking and timezone

`network_config.type` is `"iso"`, so archinstall copies the live
environment's own `systemd-networkd`/`iwd` configuration (and any saved
Wi-Fi credentials) into the installed system and enables the matching
services — the installed system gets the same networking setup that got
it online during install, no separate config to maintain. `timezone` is
set to `America/Toronto` to match the live ISO's baked-in
`/etc/localtime`.

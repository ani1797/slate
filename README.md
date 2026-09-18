# Slate

An opinionated, Arch-based Agentic OS.

## Pillars

- **Reliable** — behavior is predictable and failure modes are well understood.
- **Blazing fast** — boot, package operations, and agent workflows are optimized, not just "good enough."
- **Best in class** — when a tool or approach is chosen, it's the strongest option available, not the most convenient.
- **Well crafted** — decisions are deliberate; nothing ships half-finished.
- **Every tool must earn its keep** — no dependency, script, or abstraction is added unless it pulls clear, ongoing weight. Prefer removing over adding.

## Status

Early bootstrap. Minimal scaffold in place: an [archiso](https://wiki.archlinux.org/title/Archiso)
profile (`archiso/slate/`) for building a live/install ISO, and a packaging
convention (`packages/`) for custom Arch packages. No CI, linting, or tests yet —
tooling is added incrementally as each piece proves it earns its keep.

The ISO's desktop environment is [Hyprland](https://wiki.hyprland.org/), a
Wayland compositor, kept intentionally minimal: it auto-starts for the
unprivileged `slate` live user with a terminal (`ghostty`) and
[Vicinae](https://vicinae.com/) command palette. `Super+Space` opens the
launcher for applications, commands, script commands, and extensions. Slate
ships a dark theme and privacy-conscious defaults while keeping the user's
Vicinae settings writable. The live user has passwordless `sudo` for
installation and recovery, and `archinstall` is included for creating the
bootable Arch target.

## Layout

- `archiso/slate/` — archiso profile for Slate's x86_64 ISO. Build with
  `make build`; it first creates a local repository from Slate's packages and
  then runs `mkarchiso` (requires root and network access). Remove build
  artifacts with `make clean`.
- `packages/` — custom Arch packages, one `PKGBUILD`-based directory per
  package. It contains pinned third-party packages (including Paru) and Slate
  defaults. See `packages/README.md` for the convention.

## Installation architecture

Slate deliberately separates disk setup from Slate provisioning. Use
`archinstall` (or a manual Arch installation) to create and mount a bootable
target and create its user. Then run:

```sh
sudo slate-install /mnt <user>
```

`slate-install` installs the canonical shared manifest, enables Slate's shared
services, applies `/etc/skel` and the live-user desktop defaults to `<user>`,
and installs Slate's network and container policies. It intentionally does
**not** copy live-only autologin, archiso initramfs configuration, or the live
overlay-specific Podman storage configuration.

The manifests at
`archiso/slate/airootfs/usr/share/slate/installer/` define the boundary:
`packages.shared.x86_64` is for both ISO and installed systems;
`packages.live.x86_64` is ISO-only; `services.shared` declares target services.
The ISO build composes its archiso package input from both files and bundles the output of
`make package-repo` at `/usr/share/slate/repo`. The provisioner installs
custom packages from that bundled repository, so it remains version-matched
to the ISO and does not require the AUR or a network-hosted Slate repository.

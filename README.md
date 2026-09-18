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
Wayland compositor, kept intentionally minimal: it is launched from a
Slate-styled [tuigreet](https://github.com/tuigreet/tuigreet) login on tty1
for the unprivileged `slate` live user with a terminal (`ghostty`) and
[Vicinae](https://vicinae.com/) command palette. `Super+Space` opens the
launcher for applications, commands, script commands, and extensions. Slate
ships a dark theme and privacy-conscious defaults while keeping the user's
Vicinae settings writable. The live user has passwordless `sudo` for
installation and recovery, and `archinstall` is included for installing Arch
to disk.

## Layout

- `archiso/slate/` — archiso profile for Slate's x86_64 ISO. Build with
  `make build`; it first creates a local repository from Slate's packages and
  then runs `mkarchiso` (requires root and network access). Remove build
  artifacts with `make clean`.
- `packages/` — custom Arch packages, one `PKGBUILD`-based directory per
  package. It currently contains the pinned Vicinae binary package and Slate's
  launcher defaults. See `packages/README.md` for the convention.

The launcher packages are ready for a future Slate installer to install with
pacman, but the current unconfigured upstream `archinstall` flow does not yet
provision Slate desktop packages or user settings onto an installed system.

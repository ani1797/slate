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
installation and recovery, and `archinstall` is included for installing Arch
to disk — see `archiso/slate/airootfs/root/archinstall/README.md` for the
config-driven install flow, which provisions the full Slate desktop
(Hyprland + [greetd](https://sr.ht/~kennylevinsen/greetd/)/tuigreet, ghostty,
Vicinae, and Slate's other packages) for a user of your choice.

## Layout

- `archiso/slate/` — archiso profile for Slate's x86_64 ISO. Build with
  `make build`; it first creates a local repository from Slate's packages,
  stages it into the ISO itself (`/opt/slate-repo`, so it's reachable both
  live and by `archinstall` when installing to disk), and then runs
  `mkarchiso` (requires root and network access). Remove build artifacts
  with `make clean`.
- `packages/` — custom Arch packages, one `PKGBUILD`-based directory per
  package. It currently contains the pinned Vicinae binary package, Slate's
  default Hyprland/ghostty/direnv config, the launcher defaults, and the
  screenshot/recording tool. See `packages/README.md` for the convention.

Boot the live ISO and run `sudo archinstall --config
/root/archinstall/config.json` to install the full Slate desktop to disk —
disk layout, hostname, locale, bootloader, and the user account are left to
archinstall's normal interactive prompts, so the installed system is
configured for whoever's running the install.

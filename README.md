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
Wayland compositor, kept intentionally minimal: it auto-starts on login with
just a terminal (`foot`) bound, no launcher or bar — extras are added only
when a concrete need justifies them.

## Layout

- `archiso/slate/` — archiso profile for Slate's x86_64 ISO. Build with
  `make build` (wraps `mkarchiso -v -w work -o out archiso/slate`; requires
  root and network access) and remove build artifacts with `make clean`.
- `packages/` — custom Arch packages, one `PKGBUILD`-based directory per
  package. See `packages/README.md` for the convention. Empty until a real
  package is needed.

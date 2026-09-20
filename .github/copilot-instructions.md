# Copilot Instructions — Slate

## What this project is

Slate is an opinionated, **Arch-based Linux distro** built as an **Agentic OS** —
designed around agent-driven workflows rather than traditional interactive-only use.
Work here is Arch packaging (PKGBUILDs, pacman, archiso) plus the agent-facing
tooling built on top.

## Guiding pillars (apply to every decision, including tooling choices)

- **Reliable** — predictable behavior, well-understood failure modes.
- **Blazing fast** — boot time, package operations, and agent workflows are actively
  optimized, not left "good enough."
- **Best in class** — pick the strongest available tool/approach, not the most
  familiar or convenient one.
- **Well crafted** — no half-finished decisions; if something is added, it's done
  properly.
- **Every tool must earn its keep** — the strongest constraint on this project. Don't
  add a dependency, script, abstraction, CI job, or linter unless it provides ongoing,
  clear value. Don't scaffold structure or process speculatively.

## The two architectural rules

Almost every question about where something goes is answered by one of these.

**1. The package set is written down once.** It is the `depends=` of the `slate`
meta-package (`packages/meta/slate/PKGBUILD`). `archiso/packages.x86_64` and
`archiso/airootfs/root/archinstall/config.json` resolve *through* the metas and must
never list packages individually — that would recreate the drift this design removes.
Adding a tool to Slate means editing one `depends=` line.

**2. Anything a real Slate system needs ships in a package.** `archiso/airootfs/`
holds *only* what is meaningless outside a live session (autologin, the temporary
live `slate` user, install-media quirks). Config placed there reaches the live ISO
and silently misses every installed system.

## Directory layout

```
archiso/          archiso profile for the x86_64 live/install ISO.
                  profiledef.sh (metadata, boot modes), packages.x86_64
                  (archiso essentials + slate-live), airootfs/ (LIVE-ONLY),
                  airootfs/root/archinstall/ (config-driven install).
packages/         Slate's own Arch packages, tiered by role:
                    meta/     composition only, no files
                    bundles/  one capability each; owns its depends=, its
                              rootfs/ config tree, AND its check. Grows.
                    vendor/   pinned third-party repackaging, real checksums
                  packages/README.md is the tier contract and the recipe for
                  adding a capability. Read it before adding a package.
```

## Build and verification commands

- `make check-packages` — guard against duplicate `pkgname` across tiers.
- `make package-repo` — build every package and generate the local repo database.
  Fast, no root, no ISO. Use this to validate packaging changes.
- `make build` — full ISO. Needs root, network, and `grub` on the build host
  (mkarchiso validates the `uefi.grub` boot mode even though grub isn't in the
  ISO's package list). Slow: `paru` rebuilds from source via cargo each time, so
  batch changes into as few full builds as possible.
- `cd packages/bundles/<name> && makepkg -si` — build one package.
- `make vm-live` / `make vm-disk` / `make vm-reset` / `make vm-stop` — the VM gates.
- `slate-doctor` — the shipped self-test; runs every bundle's check and exits
  non-zero on failure. `SLATE_CHECK_DIR` overrides the check directory, which
  makes it runnable from a source checkout without installing.

`.github/workflows/publish-repo.yml` is the one real CI job: on every push to
`main` touching `packages/`, it builds every package and republishes the repo
(packages + database) to the `repo` GitHub Release, which is what an installed
system's `[slate]` pacman repo actually points at. Packages and the database
are signed there (`SLATE_SIGNING_KEY` secret imported into a scratch keyring
per run); `packages/vendor/slate-keyring` ships the matching public key so
`[slate]`'s `SigLevel = Required DatabaseOptional` can verify them. Don't add
linting or a test suite beyond this: there is still no other tooling, and
resist adding conventional boilerplate preemptively.

## Packaging rules that bite

- **Never own a path another package owns** — `pacstrap` fails hard on file
  conflicts. Verify with `pacman -Fq /the/path` before adding a file. Known
  upstream-owned paths: `/etc/pacman.conf` (pacman), `/etc/greetd/config.toml`
  (greetd), `/etc/subuid` and `/etc/subgid` (filesystem). For these, ship Slate's
  version under `/usr/share/slate/` and install it from a
  `/usr/lib/slate/first-boot.d/NN-*.sh` drop-in.
- **Bump `pkgrel` on a config change.** If the version doesn't move, `pacman -Syu`
  won't deliver it.
- **Every bundle ships a check.** A bundle with no check is not finished.
- **Never copy `/etc/skel` into existing homes from a `.install` scriptlet** — it
  clobbers the user's edits on every upgrade. Ship dotfiles twice (`/etc/skel` and
  `/usr/share/slate/config`) and let `slate-refresh-config` seed existing homes.
- Local sources use `SKIP` in `sha256sums` (git already guards them); remote sources
  in `vendor/` must pin a real hash.
- Prefer vendor drop-ins under `/usr/lib` or `/usr/share` over replacing files in
  `/etc`, so `/etc` stays the admin's override layer and upgrades produce no
  `.pacnew` churn.

## Definition of done

A change is not done when it builds. It is done when `slate-doctor` passes on a
live ISO **and** on an installed system booted with no install media attached
(`make vm-disk`) — that second one is where "fully configured out of the box" is
either true or not.

When you add real build steps, lint tooling, or tests beyond the above, **update
this file** with the actual commands and any new conventions.

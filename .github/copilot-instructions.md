# Copilot Instructions — Slate

## Project state

This repository has a minimal initial scaffold: an archiso profile and a packaging
convention. There is still no CI, no linting, and no tests — don't invent commands
or config for tooling that doesn't exist. Check the actual repo contents before
relying on anything described elsewhere (including in this file's older revisions)
as still accurate.

## Directory layout

```
archiso/slate/    Arch's archiso profile for Slate's live/install ISO (x86_64).
                   Based on archiso's upstream "baseline" profile
                   (/usr/share/archiso/configs/baseline), trimmed to the packages
                   and config actually needed. See profiledef.sh for ISO metadata
                   and boot modes, packages.x86_64 for the installed package set,
                   and airootfs/root/archinstall/ for the config-driven disk
                   install (README.md there explains it).
packages/         Custom Arch packages, one PKGBUILD-based directory per package.
                   See packages/README.md for the convention. The ISO build
                   stages these packages into a local pacman repository, which
                   `make build` also bakes into the ISO itself
                   (airootfs/opt/slate-repo, gitignored) so archinstall's
                   pacstrap can resolve them when installing to disk.
```

## Build commands

- Build all custom packages and stage the local repository:
  `make package-repo`.
- Build the ISO: `make build` (requires root, network access to fetch packages,
  and `grub` installed on the build host — needed by mkarchiso to
  validate/build the `uefi.grub` boot mode even though grub itself isn't part
  of the ISO's package list). This also stages the local package repo into
  `archiso/slate/airootfs/opt/slate-repo` before invoking `mkarchiso`.
- Build a package: `cd packages/<pkgname> && makepkg -si`.
- Install Slate to disk from the booted live ISO: `sudo archinstall --config
  /root/archinstall/config.json` — see
  `archiso/slate/airootfs/root/archinstall/README.md`.

When you add real build steps, lint tooling, or tests beyond the above, **update
this file** with the actual commands (including how to run a single test) and
any new conventions that emerge.

## What this project is

Slate is an opinionated, **Arch-based Linux distro** built as an **Agentic OS** — a
system designed around agent-driven workflows rather than traditional interactive-only
use. Expect eventual work with Arch packaging conventions (PKGBUILDs, pacman, archiso)
alongside whatever agent-facing tooling gets built on top.

## Guiding pillars (apply to every decision, including tooling choices)

- **Reliable** — predictable behavior, well-understood failure modes.
- **Blazing fast** — boot time, package operations, and agent workflows are actively
  optimized, not left "good enough."
- **Best in class** — pick the strongest available tool/approach for a job, not the
  most familiar or convenient one.
- **Well crafted** — no half-finished decisions; if something is added, it's done
  properly.
- **Every tool must earn its keep** — the strongest constraint on this project. Don't
  add a dependency, script, abstraction, CI job, or linter unless it provides ongoing,
  clear value. When in doubt, leave it out. This also means: don't scaffold structure,
  tooling, or process speculatively — add it when a real need forces the issue.

## Working in this repo right now

- There is still no CI, linting, or test suite — don't invent commands or config
  for tooling that doesn't exist.
- Because of the "earn its keep" pillar, resist the urge to add conventional
  boilerplate (CI pipelines, linters, elaborate directory scaffolding) preemptively.
  Wait until a concrete need justifies it, and prefer the minimal version that
  satisfies that need.
- Packaging work follows idiomatic Arch/archiso conventions (PKGBUILDs, `makepkg`,
  `archiso` profiles) over inventing custom packaging formats, unless a custom
  approach is demonstrably better and earns its keep.

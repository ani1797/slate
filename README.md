# Slate

An opinionated, Arch-based Agentic OS.

## Pillars

- **Reliable** — behavior is predictable and failure modes are well understood.
- **Blazing fast** — boot, package operations, and agent workflows are optimized, not just "good enough."
- **Best in class** — when a tool or approach is chosen, it's the strongest option available, not the most convenient.
- **Well crafted** — decisions are deliberate; nothing ships half-finished.
- **Every tool must earn its keep** — no dependency, script, or abstraction is added unless it pulls clear, ongoing weight. Prefer removing over adding.

## Status

Early bootstrap. An [archiso](https://wiki.archlinux.org/title/Archiso) profile
builds the live/install ISO, and `packages/` holds Slate's own Arch packages
organized into three tiers. The only CI is `.github/workflows/publish-repo.yml`,
which publishes the built package repository so installed systems can update —
everything else is `slate-doctor` plus the VM gates below, both of which ship as
product rather than as test scaffolding.

The desktop is [Hyprland](https://wiki.hyprland.org/), kept intentionally
minimal: a terminal (`ghostty`) and the [Vicinae](https://vicinae.com/) command
palette on `Super+Space`, with a dark theme and privacy-conscious defaults.

## The core idea

**The live ISO and an installed system are the same system.** The live session
is not a stripped-down demo — it is Slate, plus `archinstall`. Booting the ISO
shows exactly what installing it gives you.

That holds because the package set is written down **once**, as the `depends=`
of the `slate` meta-package. `archiso/packages.x86_64` and `archinstall`'s
`config.json` both resolve through it rather than repeating it, so the two
cannot drift apart. Adding a tool to Slate means editing one `depends=` line.

Correspondingly, **anything a real Slate system needs ships in a package.**
`archiso/airootfs/` holds only what is meaningless outside a live session —
autologin, the temporary live user, install media quirks. Config placed there
would reach the live ISO and silently miss every installed system.

## Layout

- **`packages/`** — Slate's own Arch packages, tiered into `meta/` (composition),
  `bundles/` (one capability each, owning its packages *and* its configuration
  *and* its check), and `vendor/` (pinned third-party repackaging). This is where
  nearly all work happens; see [`packages/README.md`](packages/README.md) for the
  tier contract and the recipe for adding a capability.
- **`archiso/`** — the archiso profile for the x86_64 ISO: boot configuration and
  the live-only root filesystem. See
  [`archiso/airootfs/root/archinstall/README.md`](archiso/airootfs/root/archinstall/README.md)
  for the config-driven install.
- **`Makefile`** — build and VM entry points.

## Installing

Boot the ISO and run:

```sh
sudo archinstall --config /root/archinstall/config.json
```

Disk layout, hostname, locale, bootloader, and the user account stay on
`archinstall`'s normal interactive prompts; everything Slate-specific comes from
the config. Slate's packages resolve offline from a local repository baked into
the ISO at `/var/cache/slate/repo`, so the install needs no network for them.

On first boot, `slate-first-boot.service` runs once: it installs Slate's
`pacman.conf`, allocates subordinate uid/gid ranges so rootless containers work,
runs each bundle's provisioning drop-in, and seeds the user's dotfiles.

## Updating

Once installed, `pacman -Syu` reaches Slate's own packages through a `[slate]`
repository pointing at a GitHub Release (`.github/workflows/publish-repo.yml`
rebuilds and republishes it from `packages/` on every push to `main`). This
replaces archinstall's install-media-only repo entry on first boot — see
`slate-first-boot.service` above. The repository must stay **public**: GitHub
Release assets on a private repo require an authenticated request even for
direct download links, and plain `pacman` has no way to send one.

**Signed.** Packages and the repo database are signed with Slate's dedicated
packaging key; `[slate]`'s `SigLevel` is `Required DatabaseOptional`. Trust is
established by the `slate-keyring` package (a `slate-base` dependency), which
carries the public key and populates it into pacman's keyring via
`pacman-key --populate slate` on install — the same mechanism
`archlinux-keyring` uses. The private key lives only in the
`SLATE_SIGNING_KEY` repository secret, imported into a scratch keyring inside
the CI container for each publish run and never written to disk elsewhere.
Rotating the key: generate a new one, update that secret, and re-export
`packages/vendor/slate-keyring`'s public key (bump its `pkgrel`).

Verified end-to-end against the live, published repository: a scratch pacman
root with no prior trust, using `SigLevel = Never` to install `slate-keyring`
(mirroring the ISO's offline install-time trust), then switched to
`SigLevel = Required DatabaseOptional` and confirmed `pacman -Sy` and a real
package install both succeed, and that a tampered package is rejected with a
PGP signature error.

## Verifying

`slate-doctor` is a real command shipped in `slate-base`, not a test script. It
runs every capability's check and exits non-zero on failure, identically on the
live ISO, an installed VM, and real hardware.

```sh
slate-doctor              # every capability
slate-doctor containers   # just one
slate-doctor --list       # what can be checked
```

Because each bundle ships its own check, adding a capability automatically adds
its verification.

### Building and the VM gates

```sh
make package-repo   # build all packages (fast; no ISO, no root)
make build          # full ISO (needs root, network, and grub on the host)
```

A change is not done until all three gates pass:

```sh
make vm-live        # Gate A: boot the ISO with a persistent disk attached
                    #   → Hyprland starts, `slate-doctor` passes
                    # then install to that disk from inside the session
make vm-disk        # Gate B: boot the installed disk with NO ISO attached
                    #   → greetd greets, dotfiles are seeded,
                    #     `slate-doctor` passes, `pacman -Syu` succeeds
                    # Gate C: exercise each capability by hand
```

Gate B is the one that matters most — booting with no install media is the only
way to prove the installed system stands on its own rather than leaning on the
ISO.

`make vm-reset` discards the disk for a clean run; `make vm-stop` stops the VM.
The display is on VNC at `localhost:5900` and the serial console is captured to
`.vm/serial.log` for when the display shows nothing useful.

SSH is deliberately **not** in the live image: a live ISO carrying a permissive
`sshd` and a passwordless sudo user is a real hazard on an untrusted network.

`make clean` removes all build artifacts.

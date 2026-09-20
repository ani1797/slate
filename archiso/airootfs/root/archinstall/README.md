# Installing Slate to disk

Boot the live ISO and run:

```sh
sudo archinstall --config /root/archinstall/config.json
```

Anything genuinely machine- or user-specific — disk layout, hostname, locale,
bootloader, username and password — is deliberately **not** in `config.json`;
archinstall prompts for those interactively.

## One package, one source of truth

`config.json`'s `packages` list is exactly `["slate"]`.

`slate` is a meta-package whose `depends=` names every capability bundle
(`slate-base`, `slate-desktop`, `slate-shell`, `slate-launcher`,
`slate-capture`, `slate-dev`, `slate-containers`, plus `paru`). The live ISO's
`packages.x86_64` resolves through the same metas via `slate-live`.

So the package set is written down once, in `packages/meta/slate/PKGBUILD`, and
the installed system cannot drift from the live one. Nothing — not pipewire, not
greetd, not the dev runtimes — is listed here as well; a second list is a second
source of truth.

This is also why `audio_config` is **not** set. `slate-desktop` already depends
on the pipewire stack, and letting archinstall install it separately would
reintroduce exactly the drift the meta-package removes.

## How Slate's own packages resolve

Slate's packages exist only in its own locally-built pacman repository, not in
`[core]`/`[extra]`. `make build` stages that repository into the ISO at
`/var/cache/slate/repo`, and `mirror_config.custom_repositories` registers it so
pacstrap can resolve them — offline, with no network required for Slate's half
of the install.

`sign_check` is `"Never"` rather than `"Optional"`: the packages are unsigned
and built locally, and `SigLevel = Optional TrustAll` is documented to fail
under `pacstrap`.

## What happens on first boot

`config.json` carries **no `custom_commands`**. Shell logic embedded in JSON is
not version-controlled as code, not testable, and not reusable after the install
finishes. Everything it used to do now lives in `slate-base` as real files, run
once by `slate-first-boot.service`:

- **`/etc/pacman.conf` is replaced** with Slate's packaged version. This matters:
  archinstall appends `custom_repositories` verbatim to the target's
  `pacman.conf`, so every installed system would otherwise be left with a
  `Server = file:///var/cache/slate/repo` entry pointing at a path that only
  exists on the ISO — breaking the first `pacman -Syu` after reboot. It is also
  appended *after* `[core]`/`[extra]`, which would give Slate's own packages the
  lowest resolution priority.
- **Subordinate uid/gid ranges are allocated** for each human user, so rootless
  podman works. `/etc/subuid` and `/etc/subgid` are owned by the `filesystem`
  package and so can never be shipped by a Slate package.
- **Each bundle's provisioning drop-in runs** from `/usr/lib/slate/first-boot.d/`
  — this is how `slate-desktop` installs `/etc/greetd/config.toml`, a path the
  `greetd` package owns and which a Slate package therefore cannot ship without
  causing a `pacstrap`-breaking file conflict.
- **Dotfiles are seeded** into every existing user's home. archinstall creates
  the user account *before* installing packages, so `/etc/skel` is still empty at
  that moment. Bundles ship their dotfiles twice — to `/etc/skel` for future
  users, and to `/usr/share/slate/config` for `slate-refresh-config` to seed
  existing homes from, non-destructively.

`slate-refresh-config` stays available afterwards to re-seed any new defaults a
later upgrade introduces.

## Networking and timezone

`network_config.type` is `"iso"`, so archinstall copies the live environment's
own `systemd-networkd`/`iwd` configuration — including any saved Wi-Fi
credentials — into the installed system and enables the matching services. The
installed system gets the same networking that got it online during the install.

`timezone` is `America/Toronto`, matching the live ISO's baked-in
`/etc/localtime`. Locale is left to archinstall's prompt.

## Verifying the result

After rebooting into the installed system:

```sh
slate-doctor
```

It exits non-zero if any capability is misconfigured. See the repository README
for the full VM gate workflow.

# Packages

Everything Slate *is* lives here. The ISO installs these packages and so does
`archinstall`, which is what makes a freshly installed system identical to the
live session rather than a stripped-down version of it.

Packages are standard Arch `PKGBUILD`s — no custom format, no build wrapper —
organized into three tiers by **role**. The tier tells you what belongs in it,
so a new package has exactly one correct home.

```
packages/
├── meta/                  # composition only — no files
│   ├── slate/             # what a real Slate system is made of
│   └── slate-live/        # slate + install-media-only extras
├── bundles/               # one capability per directory (this tier grows)
│   ├── slate-base/        # provisioning, pacman config, slate-doctor
│   ├── slate-desktop/     # compositor, session, greeter, portals, fonts
│   ├── slate-shell/       # terminal and shell environment
│   ├── slate-launcher/    # Vicinae plus Slate's theme and defaults
│   ├── slate-capture/     # screenshot and screen recording
│   ├── slate-dev/         # language runtimes
│   ├── slate-containers/  # rootless podman stack
│   └── slate-ssh/         # per-user ssh-agent, client defaults, hardened sshd
└── vendor/                # third-party repackaging, pinned upstream
    ├── vicinae-bin/
    └── paru/
```

## The three tiers

### `meta/` — composition

Pure `depends=`, empty `package()`, ships no files. This is the **single
definition of Slate's package set**. `archiso/packages.x86_64` and
`archinstall`'s `config.json` both resolve through these metas instead of
repeating the list, so the live image and an installed system cannot drift.

A meta-package rather than a pacman group, deliberately: only a meta-package
propagates *newly added* members to existing systems on `pacman -Syu`. A group
does not.

The tradeoff, which is inherent to meta-packages: because `slate` uses
`depends=`, removing one bundle also removes the `slate` meta. A genuinely
optional capability belongs in `optdepends=` and is installed explicitly.

### `bundles/` — one capability, self-contained

A bundle owns **three** things:

1. the packages it pulls in — `depends=`
2. the configuration that makes them Slate-flavored — a `rootfs/` tree
3. the check that proves it works — `rootfs/usr/share/slate/checks/<name>.sh`

`rootfs/` mirrors the real filesystem and `package()` is a single `cp -a`, so
**adding configuration or a check is just "put the file at the right path"** —
no `source=` entry, no `sha256sums` line, no `PKGBUILD` edit at all.

### `vendor/` — repackaging only

Pinned upstream sources with **real checksums**, containing no Slate opinion.
Separate because the maintenance rhythm differs: these are bumped when upstream
releases, not when Slate's design changes. `vicinae-bin` packages the binary;
`slate-launcher` configures it, so neither bump disturbs the other.

## Conventions

- Bundle name is `slate-<capability>`, matching both the directory and
  `pkgname`. Names follow [Arch package naming rules](https://wiki.archlinux.org/title/Arch_package_guidelines#Package_naming).
- **Where a config file goes:**
  | Kind | Path |
  |---|---|
  | Vendor default with a drop-in mechanism | `/usr/lib/**` or `/usr/share/**` |
  | Config with no drop-in mechanism | `/etc/**` |
  | User dotfiles | `/etc/skel/**` *and* `/usr/share/slate/config/**` |
- **Never own a path another package owns.** `pacstrap` fails hard on file
  conflicts. Check with `pacman -Fq /the/path` before adding it. Where upstream
  already owns the file (`/etc/pacman.conf`, `/etc/greetd/config.toml`,
  `/etc/subuid`), ship Slate's version under `/usr/share/slate/` and install it
  from a first-boot drop-in instead.
- **A bundle never reaches into another bundle's paths.** Shared plumbing
  belongs to `slate-base`.
- **Every bundle ships a check.** A bundle with no check is not finished.
- **Bump `pkgrel` on a config change**, `pkgver` on a meaningful feature change.
  If neither moves, `pacman -Syu` will not deliver the change.
- Local sources use `SKIP` in `sha256sums`: they are version-controlled, so git
  already guards them and a checksum would only add edit friction. Remote
  sources in `vendor/` must pin a real hash.
- Dotfiles are shipped **twice** — to `/etc/skel` for new users, and to
  `/usr/share/slate/config` so `slate-refresh-config` can seed *existing* homes.
  Never copy skel into existing homes from a `.install` scriptlet; it silently
  clobbers the user's own edits on every upgrade.

## Adding a capability

1. `mkdir -p packages/bundles/slate-<name>/rootfs`
2. Write the `PKGBUILD`. The body is boilerplate — only `depends=` is interesting:

   ```bash
   pkgname=slate-<name>
   pkgver=1.0.0
   pkgrel=1
   pkgdesc="..."
   arch=('any')
   url="https://github.com/ani1797/slate"
   license=('MIT')
   depends=(slate-base ...)
   source=()
   sha256sums=()

   package() {
     cp -a "$startdir/rootfs/." "$pkgdir/"
   }
   ```
3. Drop configuration into `rootfs/` at its real filesystem path.
4. Write `rootfs/usr/share/slate/checks/slate-<name>.sh` asserting the
   capability actually works — see any existing bundle for the helpers
   (`check`, `check_file`, `check_dir`, `check_not`, `have`, `as_user`,
   `skip`, `is_root`, `slate_is_live`).
5. Add it to `depends=` in `packages/meta/slate/PKGBUILD`.
6. `make check-packages && make package-repo` to confirm it builds.

Needs to run once at install time (allocating ids, installing a file upstream
owns)? Add a numbered drop-in at `rootfs/usr/lib/slate/first-boot.d/NN-<name>.sh`
rather than editing `slate-base`'s script.

## Building

```sh
make check-packages   # guard against duplicate pkgnames across tiers
make package-repo     # build every package, generate the local repo database
make build            # the above, staged into a full ISO
```

Every directory under `packages/` containing a `PKGBUILD` is discovered
automatically at any depth, so there is no list to keep in sync.

To build and install a single package on the host:

```sh
cd packages/bundles/slate-<name> && makepkg -si
```

Artifacts live under `.build/` and are removed by `make clean`.

# Packages

Custom packages for Slate live here as standard Arch `PKGBUILD`s, one directory
per package:

```
packages/
├── <pkgname>/
│   └── PKGBUILD
├── slate-launcher/
└── vicinae-bin/
```

## Conventions

- `<pkgname>` matches the package's `pkgname` in its `PKGBUILD` and follows
  [Arch package naming rules](https://wiki.archlinux.org/title/Arch_package_guidelines#Package_naming)
  (lowercase, no spaces, `-` as the only separator).
- Each package directory is self-contained: `PKGBUILD` plus any local sources
  it references (patches, `.install` scripts, etc.).
- No custom packaging format or build wrapper — packages are built the
  standard way with `makepkg`.
- Third-party software, including AUR software, is packaged locally from a
  pinned upstream source and verified checksum. ISO builds never invoke an AUR
  helper or consume the AUR directly.
- Package-owned defaults belong under `/usr/share` or `/etc/skel`; do not
  overwrite mutable files in existing users' home directories.

## Building a package locally

```sh
cd packages/<pkgname>
makepkg -si
```

To build every package without installing its runtime dependencies on the host
and stage the local repository used by archiso:

```sh
make package-repo
```

Release builds require Arch's `devtools` and a local GPG signing key:

```sh
make build SIGNING_KEY=<fingerprint-or-key-id>
```

Packages are built with `makechrootpkg` in a clean `mkarchroot` build root as
an unprivileged build user. Artifacts and the local `slate` repository database
are signed, then bundled in the ISO for `slate-install`; the ISO build uses the
exported public key to verify that repository. Package, chroot, keyring, source,
and repository artifacts live under `.build/` and are removed by `make clean`.

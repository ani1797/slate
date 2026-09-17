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
- Binary repackaging must pin an upstream release and checksum. ISO builds
  never consume the AUR directly.
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

`make build` runs this step automatically, generates a build-specific pacman
configuration pointing at `.build/repo`, and passes that configuration to
`mkarchiso`. Package and repository artifacts live under `.build/` and are
removed by `make clean`.

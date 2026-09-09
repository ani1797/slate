# Packages

Custom packages for Slate live here as standard Arch `PKGBUILD`s, one directory
per package:

```
packages/
└── <pkgname>/
    └── PKGBUILD
```

## Conventions

- `<pkgname>` matches the package's `pkgname` in its `PKGBUILD` and follows
  [Arch package naming rules](https://wiki.archlinux.org/title/Arch_package_guidelines#Package_naming)
  (lowercase, no spaces, `-` as the only separator).
- Each package directory is self-contained: `PKGBUILD` plus any local sources
  it references (patches, `.install` scripts, etc.).
- No custom packaging format or build wrapper — packages are built the
  standard way with `makepkg`.

## Building a package locally

```sh
cd packages/<pkgname>
makepkg -si
```

This is currently an empty convention — packages are added here as Slate
needs them.

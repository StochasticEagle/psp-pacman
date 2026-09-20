# PSP Pacman

This repository contains the PSPDEV-specific package-manager layer built on top of Pacman. It provides the PSP package database/configuration, package-build wrapper, installation wrapper, and the small set of Pacman source changes required by PSPDEV.

The package installs two user-facing commands:

- **psp-pacman** — installs and manages packages under the active `$PSPDEV` prefix.
- **psp-makepkg** — builds PSP packages from `PSPBUILD` files using the active `$PSPDEV` toolchain and package metadata.

## Dependencies

On Ubuntu/Debian, install:

- build-essential
- libarchive-dev
- libarchive-tools
- libcurl4-openssl-dev
- libgpgme-dev
- libssl-dev
- pkg-config
- meson
- ninja-build
- wget

On Arch/Manjaro, install:

- base-devel

## Installation

1. Install the host dependencies.
2. Set `$PSPDEV` to the PSPDEV installation prefix and confirm it with `echo "$PSPDEV"`.
3. Build and install:

```sh
./build-and-install.sh
```

Build steps run with the permissions of the invoking process. Installation uses `install-permissions.sh` to test the actual PSPDEV prefix permissions. If the prefix is writable, installation proceeds without elevation; if it is not writable, only the installation command is run through `sudo`. Prefix ownership is not used as the privilege decision.

For a completely fresh rebuild, run `./clean.sh` before `./build-and-install.sh`. Normal builds preserve the existing source and Meson build state for incremental compilation.

## Usage

### Installing a package

Install a PSP package with:

```sh
psp-pacman -U package-name-1.0.2.pkg.tar.gz
```

`psp-pacman` uses the same permission helper as the installer. A writable `$PSPDEV` prefix is managed directly by the current user; a non-writable prefix elevates only the Pacman operation.

### Building a package

Package builds use a `PSPBUILD` file rather than `PKGBUILD`:

```sh
psp-makepkg
```

`psp-makepkg` configures host `pkg-config` for PSP cross-compilation by using `$PSPDEV` as the sysroot and limiting package discovery to PSP package metadata under `$PSPDEV/psp`.

Install package contents below `$pkgdir/psp` in the `PSPBUILD`; those paths become `$PSPDEV/psp` when the package is installed.

## Permission tests

The permission tests exercise both writable and non-writable PSPDEV prefixes, including a case where the prefix itself is writable but an existing nested installation directory is not:

```sh
./tests/test-install-permissions.sh
```

Run the test as a non-root user so filesystem write permissions are evaluated normally. CI runs it this way on container jobs and directly on hosted runners.

## Pacman source policy

`components/pacman` remains a shallow submodule of upstream Pacman. During `prepare()`, the build copies that source and applies the three PSP-specific patches:

- `pacman-7.1.0-psp-strip.patch`
- `pacman-7.1.0-rootless.patch`
- `pacman-7.1.0-add-asroot-option.patch`

For now, keeping these changes as explicit patches is preferred: the PSP delta is small, reviewable, and the upstream source relationship stays obvious. A dedicated PSP Pacman source fork becomes justified if these patches grow substantially, become interdependent, require frequent rebasing because of upstream churn, or need an independent release cadence. Until then, the submodule-plus-patches model keeps the maintenance surface smaller.

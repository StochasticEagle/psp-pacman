# PSP Pacman

This respository contains all the files needed to build and install the pacman package managed for the PSP toolchain. Pacman can be used to build and manage packages for the PSP development.

This package provides the following commands:
- **psp-pacman** - Allows users to install and manage PSPDEV packages.
- **psp-makepkg** - Allows users to build packages from PSPBUILD files.

## Dependencies

On Ubuntu/Debian, the following packages need to be installed:
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

On Arch/Manjaro, the following packages need to be installed:
- base-devel

## Installation
1. Install the dependencies.
2. Make sure the environment variable ``$PSPDEV`` is set in your shell. Use ``echo $PSPDEV`` to confirm this.
3. Install with the following command:
```
./build-and-install.sh
```

## Usage

Here is how to use ``psp-pacman`` and ``psp-makepkg``.

### Installing a package

Installing a ``*.pkg.tar.gz`` package with a PSP library can be done with:
```
psp-pacman -U package-name-1.0.2.pkg.tar.gz
```

### Building a package

Building a package requires a ``PSPBUILD`` script. Here is [an example](https://git.archlinux.org/pacman.git/plain/proto/PKGBUILD.proto) and [some documentation on which options are available](https://wiki.archlinux.org/index.php/PKGBUILD). Do **not** call it ``PKGBUILD``, though, use ``PSPBUILD`` instead. Also make sure to install libraries in ``$pkgdir/psp/lib`` in your build script, since this will translate to ``$PSPDEV/psp/lib`` when installing.

Packages can be build by running the following command in a directory with a PSPBUILD file in it:
```
psp-makepkg
```

This will create a file called something like ``package-name-1.0.2.pkg.tar.gz``. This file can be shared or installed. Installing would be done using the following command:
```
psp-pacman -U package-name-1.0.2.pkg.tar.gz
```

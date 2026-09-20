#!/usr/bin/env bash
# build-and-install.sh by Wouter Wijsman (wwijsman@live.nl)

# Exit on errors
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT}/install-permissions.sh"

## Remove $CC and $CXX for configure
unset CC
unset CXX

## Make sure PSPDEV is set
if [ -z "${PSPDEV}" ]; then
    echo "The PSPDEV environment variable has not been set"
    exit 1
fi

## Enter the script directory.
cd "$(dirname "$0")"
WORKDIR="${PWD}"

## MacOS specific environment variables
if [ "$(uname -s)" == "Darwin" ]; then
    export PATH="$(brew --prefix gnu-sed)/libexec/gnubin:$(brew --prefix bash)/bin:$PATH"
    export PKG_CONFIG_PATH="$(brew --prefix libarchive)/lib/pkgconfig"
fi

## Preserve prior source/build state for incremental rebuilds.
## Use ./clean.sh when a fresh build is required.

## Install makepkg from source if it isn't already available and build the package
if ! which makepkg > /dev/null; then
    echo "Did not find makepkg, downloading and building pacman from source"
    source PSPBUILD
    export pkgdir="${PWD}/temp_build/psp-pacman"
    mkdir -p "${pkgdir}"
    prepare
    cd "$WORKDIR"
    build
    cd "$WORKDIR"
    package
    cd "$WORKDIR"
    export PATH="${pkgdir}/share/pacman/bin:${PATH}"
    CARCH="$(./get-arch)" PSPDEV="${pkgdir}" makepkg -p PSPBUILD .
else
    makepkg_args=(-f -p PSPBUILD .)
    if compgen -G "src/pacman-v*/build/build.ninja" > /dev/null; then
        makepkg_args=(--noextract "${makepkg_args[@]}")
    fi
    CARCH="$(./get-arch)" makepkg "${makepkg_args[@]}"
fi

## Create the required directories for installation
pspdev_run_install mkdir -m 755 -p "${PSPDEV}/var/lib/pacman"

## Add the directory with pacman's binaries to the start of the PATH
export PATH="${PWD}/pkg/psp-pacman/share/pacman/bin:${PATH}"

export LD_LIBRARY_PATH="${PWD}/pkg/psp-pacman/lib:${LD_LIBRARY_PATH}"

## The package in $PSPDEV using the pacman that was build
pspdev_run_install ./pkg/psp-pacman/share/pacman/bin/pacman \
    --root "${PSPDEV}" \
    --dbpath "${PSPDEV}/var/lib/pacman" \
    --config "pacman.conf" \
    --arch "$(./get-arch)" \
    --noconfirm \
    -U psp-pacman-*.pkg.tar.*

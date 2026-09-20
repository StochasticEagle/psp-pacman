#!/usr/bin/env bash

set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

rm -rf temp_build pkg src
rm -f psp-pacman-*.pkg.tar.*

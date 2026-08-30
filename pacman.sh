#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
exec ./build-and-install.sh "$@"

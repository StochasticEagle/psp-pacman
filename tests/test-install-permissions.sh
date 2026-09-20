#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/install-permissions.sh"

if (( EUID == 0 )); then
    echo "ERROR: permission tests must run as a non-root user" >&2
    exit 1
fi

TMPDIR_TEST="$(mktemp -d)"
cleanup() {
    chmod -R u+w "${TMPDIR_TEST}" 2>/dev/null || true
    rm -rf "${TMPDIR_TEST}"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

mkdir -p "${TMPDIR_TEST}/bin"
cat > "${TMPDIR_TEST}/bin/sudo" <<'STUB'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "${TEST_LOG}"
exec "$@"
STUB
chmod 755 "${TMPDIR_TEST}/bin/sudo"
export PATH="${TMPDIR_TEST}/bin:${PATH}"

# A writable prefix, including existing nested directories, must not elevate.
PSPDEV="${TMPDIR_TEST}/writable-prefix"
export PSPDEV
mkdir -p "${PSPDEV}/var/lib/pacman"
pspdev_prefix_is_writable || fail "writable PSPDEV prefix was reported non-writable"
unset PSPDEV_INSTALL_ELEVATED || true
pspdev_prepare_install
[[ "${PSPDEV_INSTALL_ELEVATED}" == 0 ]] || fail "writable PSPDEV prefix requested elevation"

# A writable top-level prefix with a non-writable nested directory must elevate.
PSPDEV="${TMPDIR_TEST}/non-writable-prefix"
export PSPDEV
mkdir -p "${PSPDEV}/var/lib/pacman"
chmod 0555 "${PSPDEV}/var/lib/pacman"
if pspdev_prefix_is_writable; then
    fail "non-writable PSPDEV prefix was reported writable"
fi
unset PSPDEV_INSTALL_ELEVATED || true
pspdev_prepare_install
[[ "${PSPDEV_INSTALL_ELEVATED}" == 1 ]] || fail "non-writable PSPDEV prefix did not request elevation"
chmod 0755 "${PSPDEV}/var/lib/pacman"

setup_fake_prefix() {
    local prefix="$1"

    mkdir -p \
        "${prefix}/bin" \
        "${prefix}/etc/pacman.d/gnupg" \
        "${prefix}/etc/pacman.d/hooks" \
        "${prefix}/share/libalpm/hooks" \
        "${prefix}/share/pacman/bin" \
        "${prefix}/share/psp-pacman" \
        "${prefix}/var/cache/pacman/pkg" \
        "${prefix}/var/lib/pacman" \
        "${prefix}/var/log"

    cp "${ROOT}/install-permissions.sh" "${prefix}/share/psp-pacman/install-permissions.sh"

    cat > "${prefix}/share/pacman/bin/get-arch" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' test_arch
STUB

    cat > "${prefix}/share/pacman/bin/pacman" <<'STUB'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >> "${TEST_LOG}"
STUB

    chmod 755 \
        "${prefix}/share/pacman/bin/get-arch" \
        "${prefix}/share/pacman/bin/pacman"
}

# psp-pacman must use the same helper and avoid sudo for a writable prefix.
PSPDEV="${TMPDIR_TEST}/wrapper-writable"
export PSPDEV
setup_fake_prefix "${PSPDEV}"
TEST_LOG="${TMPDIR_TEST}/writable.log"
export TEST_LOG
: > "${TEST_LOG}"
"${ROOT}/psp-pacman" -V
grep -q '^pacman ' "${TEST_LOG}" || fail "psp-pacman did not invoke pacman"
if grep -q '^sudo ' "${TEST_LOG}"; then
    fail "psp-pacman elevated for a writable PSPDEV prefix"
fi

# A non-writable nested path must take the sudo path rather than relying on
# ownership or a top-level touch test.
PSPDEV="${TMPDIR_TEST}/wrapper-non-writable"
export PSPDEV
setup_fake_prefix "${PSPDEV}"
chmod 0555 "${PSPDEV}/var/lib/pacman"
TEST_LOG="${TMPDIR_TEST}/non-writable.log"
export TEST_LOG
: > "${TEST_LOG}"
"${ROOT}/psp-pacman" -V
grep -q '^sudo ' "${TEST_LOG}" || fail "psp-pacman did not elevate for a non-writable PSPDEV prefix"
grep -q '^pacman ' "${TEST_LOG}" || fail "elevated psp-pacman path did not invoke pacman"

echo "install-permission tests passed"

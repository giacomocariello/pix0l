#!/usr/bin/env bash
# Push the local signing material into GitHub Actions secrets, and set the
# non-secret build variables. Requires an authenticated `gh` (or `nix run
# nixpkgs#gh`). Run after generate-keys.sh and after the repo exists.
set -euo pipefail
cd "$(dirname "$0")/.."
GH="${GH:-gh}"
REPO="${REPO:-giacomocariello/pix0l}"

b64() { base64 < "$1" | tr -d '\n'; }

echo "Setting secrets on $REPO ..."
"$GH" secret set KEY_AVB_BASE64  -R "$REPO" -b "$(b64 keys/avb.key)"
"$GH" secret set KEY_OTA_BASE64  -R "$REPO" -b "$(b64 keys/ota.key)"
"$GH" secret set CERT_OTA_BASE64 -R "$REPO" -b "$(b64 keys/ota.crt)"
"$GH" secret set PASSPHRASE_AVB  -R "$REPO" -b "$(cat keys/avb.passphrase)"
"$GH" secret set PASSPHRASE_OTA  -R "$REPO" -b "$(cat keys/ota.passphrase)"

# Non-secret build config (safe to be public):
"$GH" variable set MAGISK_SOURCE  -R "$REPO" -b "pixincreate/Magisk"
"$GH" variable set MAGISK_VERSION -R "$REPO" -b "v31.0-3"
# MAGISK_PREINIT_DEVICE stays UNSET until you read it off the device (see docs/install.md).
# While unset, CI builds the rootless flavor only. To enable Magisk:
#   gh variable set MAGISK_PREINIT_DEVICE -R "$REPO" -b "<value from device>"

echo "Secrets + variables set. MAGISK_PREINIT_DEVICE intentionally left unset (rootless-first)."

#!/usr/bin/env bash
# Generate the signing keys that become your device's root of trust.
# Run ONCE, locally. Back up keys/ offline (encrypted). NEVER commit it.
#
# Produces:
#   keys/avb.key         encrypted PKCS8 RSA-4096  (vbmeta signing)
#   keys/ota.key         encrypted PKCS8 RSA-4096  (OTA signing)
#   keys/ota.crt         certificate for ota.key
#   keys/avb_pkmd.bin    AVB public key -> flashed to the device (avb_custom_key)
#   keys/avb.passphrase  keys/ota.passphrase
set -euo pipefail
cd "$(dirname "$0")/.."
AVBROOT="${AVBROOT:-avbroot}"   # from the flake dev shell (nix develop / direnv)
mkdir -p keys
[ -e keys/avb.key ] && { echo "keys/ already populated; refusing to overwrite"; exit 1; }

export PASS_AVB="$(openssl rand -base64 24)"
export PASS_OTA="$(openssl rand -base64 24)"
"$AVBROOT" key generate-key -t rsa4096 --pass-env-var PASS_AVB -o keys/avb.key
"$AVBROOT" key generate-key -t rsa4096 --pass-env-var PASS_OTA -o keys/ota.key
"$AVBROOT" key generate-cert -k keys/ota.key --pass-env-var PASS_OTA -o keys/ota.crt
"$AVBROOT" key encode-avb   -k keys/avb.key --pass-env-var PASS_AVB -o keys/avb_pkmd.bin
printf '%s' "$PASS_AVB" > keys/avb.passphrase
printf '%s' "$PASS_OTA" > keys/ota.passphrase

echo "Done. AVB public key fingerprint (verify this on-device after relock):"
sha256sum keys/avb_pkmd.bin 2>/dev/null || shasum -a 256 keys/avb_pkmd.bin
echo "Now run scripts/set-secrets.sh to push these into GitHub Actions secrets."

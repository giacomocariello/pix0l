# pix0l — project instructions

Owner: Giacomo Cariello. Public repo: `giacomocariello/pix0l`.

**What this is:** an automated pipeline that turns each stock GrapheneOS release for the
**Pixel 10 Pro Fold** (codename **`rango`**) into a **rooted, self-signed, OTA-updatable**
build for a **relocked** bootloader — running on free CI, served from free hosting. No AOSP
build; it re-signs prebuilt OTAs.

## Goal & constraints (don't relitigate these)
- Root exists for **comprehensive backups** (Neo Backup; Seedvault skips `allowBackup=false`).
- Target is Play Integrity **DEVICE** tier. **STRONG is deliberately out of scope** — it's
  unreachable on any non-Google-keyed OS, and the keybox route is a dead end. Apps that hard-
  require STRONG (e.g. Revolut) are expected casualties, not bugs to fix here.
- Chosen root: **pixincreate/Magisk** fork (fixes Zygisk on GrapheneOS). Not Kitsune/Delta
  (better hider but archived Aug 2025 → breaks on new hardware + an auto-updating pipeline).

## Dev environment
`direnv allow` (or `nix develop`) loads the flake dev shell with: `avbroot`, `adb`/`fastboot`
(android-tools), `custota-tool`, `gh`, `git`, `jq`, `curl`, `openssl`, `ssh-keygen`, `unzip`.
Use these from PATH — don't re-vendor binaries into the repo.

## How it works
`.github/workflows/build.yml`, daily + `workflow_dispatch`:
1. Resolve latest `rango` `stable` version (`https://releases.grapheneos.org/rango-stable`).
2. Download + verify `avbroot`/`custota-tool` (ssh-keygen against chenxiaolong's key).
3. Download the stock OTA; restore signing keys from secrets.
4. `avbroot ota patch` → **rootless** always; **magisk** too iff `MAGISK_PREINIT_DEVICE` set.
5. **Verify** each patched OTA against our OTA cert + AVB key (gate before publish).
6. Publish OTA zips + `.csig` to a **Release** (tag = version); publish Custota `rango.json`
   to **Pages** at `https://giacomocariello.github.io/pix0l/{rootless,magisk}/rango.json`.

## Operating it
- Trigger: `gh workflow run build.yml -R giacomocariello/pix0l [-f force=true]`.
- Watch: `gh run watch <id> -R giacomocariello/pix0l`; failures: `gh run view <id> --log-failed`.
- Release step is idempotent; a version already released is skipped unless `force=true`.
- Pages is pre-enabled (source = GitHub Actions); the workflow does not try to create it.

## Secrets & variables (already set)
- Secrets: `KEY_AVB_BASE64`, `KEY_OTA_BASE64`, `CERT_OTA_BASE64`, `PASSPHRASE_AVB`, `PASSPHRASE_OTA`.
- Variables: `MAGISK_SOURCE=pixincreate/Magisk`, `MAGISK_VERSION=v31.0-3`.
- **Pending:** `MAGISK_PREINIT_DEVICE` — read off the device once (Magisk-patch `init_boot`
  → `avbroot boot magisk-info`), then `gh variable set …`. Until set, only rootless builds.

## Keys = root of trust (critical)
`keys/` (gitignored) holds `avb.key`, `ota.key`, `ota.crt`, `avb_pkmd.bin`, passphrases.
**Never commit them.** They must be backed up offline; if they leak, the relock is worthless.
`avb_pkmd.bin` is what gets flashed as `avb_custom_key` on the device.

## Device install
See `docs/install.md`. Always: **keep OEM unlocking ENABLED** (only brick-recovery path),
**boot the patched image before relocking**, and **sideload** OTAs (don't fastboot-flash them).

## Conventions
- Git commits: **one-line subject only** — no body, no `Co-Authored-By` trailer.
- Nix-first (flakes via flake-parts). Keep devShell `shellHook` to one short echo.

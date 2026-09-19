# On-device install, relock, and Magisk enablement (Pixel 10 Pro Fold, `rango`)

> Read this fully first. A mistake while **locked** can require unlock+wipe to recover.
> **Keep "OEM unlocking" ENABLED the whole time** — it is your only recovery path.

## 0. Prerequisites
- `fastboot` (recent platform-tools), USB-C cable.
- The patched OTA for the current version from this repo's Releases:
  `rango-<version>-rootless.zip` (first pass) — later `-magisk.zip`.
- Your `keys/avb_pkmd.bin` (from `scripts/generate-keys.sh`).

## 1. Clean-flash stock GrapheneOS first
Follow <https://grapheneos.org/install/cli> to unlock the bootloader and flash the official
`rango` factory image. Boot it once. (This ensures a known-good baseline + firmware.)

## 2. Install the patched OTA (first time = fastboot, NOT sideload)
The **first** install onto stock GrapheneOS must go through fastboot. Stock recovery
verifies OTA signatures against its `otacerts.zip`, which trusts only GrapheneOS's key, so
it **rejects our self-signed OTA**. avbroot re-signs `vbmeta` and swaps `otacerts.zip` into
system/recovery, so only **after** the patched OS is running does recovery trust our key —
at which point `adb sideload` (and Custota) work for later updates.

First install (bootloader unlocked, device in fastboot):
```sh
avbroot ota extract --input rango-<version>-rootless.zip --directory extracted --fastboot
ANDROID_PRODUCT_OUT=extracted fastboot flashall --skip-reboot   # auto-hops to fastbootd
```
Later updates only (once running a patched build; may be done while locked):
```sh
adb reboot recovery          # in recovery: Apply update -> ADB
adb sideload rango-<version>-rootless.zip
```

## 2b. Boot and verify BEFORE locking (critical)
Reboot into the patched OS and confirm it boots and works normally **while still
unlocked**. Never relock an image you haven't seen boot — locking a bad image is the
main way people brick. Only proceed once it's booted cleanly.

## 3. Install your AVB key and relock
```sh
adb reboot bootloader
fastboot erase avb_custom_key
fastboot flash avb_custom_key keys/avb_pkmd.bin
fastboot flashing lock        # confirm on-device with volume/power
```
On reboot you'll see the **yellow** verified-boot screen showing your key fingerprint —
this is correct. Compare it against the `avb_pkmd.bin` SHA-256 you recorded.

## 4. Enable the Magisk flavor (one-time preinit discovery)
The Magisk build needs a device-specific `preinit` partition. Read it off the device once:

1. On the running device, install the **pixincreate Magisk** APK and use it to **patch the
   stock `init_boot.img`** (from the factory image) → produces `magisk_patched-XXXX.img`.
2. Pull it and read the value:
   ```sh
   avbroot boot magisk-info --image magisk_patched-*.img   # prints PREINITDEVICE=<name>
   ```
3. Set it as a repo variable and rebuild:
   ```sh
   gh variable set MAGISK_PREINIT_DEVICE -R giacomocariello/pix0l -b "<name>"
   gh workflow run build.yml -R giacomocariello/pix0l -f force=true
   ```
4. Install the resulting `rango-<version>-magisk.zip`: sideload it from recovery (works now —
   the running patched OS trusts our OTA key — and is fine while locked), or fastboot-flash
   it as in step 2. On next boot you're rooted + locked.

## 5. Custota (seamless OTAs while locked) — requires root, so do this AFTER step 4
Custota is a **Magisk/KernelSU module** (no standalone APK); it needs root to talk to
`update_engine`, so it only runs on the **magisk** flavor.
- Install the `Custota-<ver>-release.zip` module in Magisk, reboot, then open Custota.
- Set the OTA server URL: `https://giacomocariello.github.io/pix0l/magisk/`
  (Custota appends `rango.json` automatically.)
- Custota will then offer each new version as a seamless A/B update, even while locked.

On the **rootless** flavor there is no Custota — update by manual recovery sideload (step 2,
"later updates"), since stock's updater won't accept our self-signed OTAs either.

## Recovery (if a boot fails)
- **Do NOT switch slots.** Reboot to bootloader.
- `fastboot flashing unlock` (works because OEM unlocking is enabled) → wipes → re-flash
  stock via the Android Flash Tool (<https://flash.android.com>) → start over.
- This is why backups matter: recovery costs data, not the device.

## Root-detection hiding (optional, DEVICE-tier only)
See the repo notes on Magisk fork choice. On the pixincreate fork: enable **Zygisk**, add
apps to the **DenyList**, and use a **Play Integrity Fix** module. STRONG stays unreachable.

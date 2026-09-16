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

## 2. Sideload the patched OTA
avbroot OTAs are **sideloaded**, not fastboot-flashed (avoids "device corrupt").
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

## 4. Custota (seamless OTAs while locked)
- Install the Custota app (from the `Custota-<ver>-release.zip` on chenxiaolong/Custota).
- Set the OTA server URL to the flavor you want:
  - rootless: `https://giacomocariello.github.io/pix0l/rootless/`
  - magisk:   `https://giacomocariello.github.io/pix0l/magisk/`
  - (Custota appends `rango.json` automatically.)
- Custota will now offer each new version as a seamless A/B update.

## 5. Enable the Magisk flavor (one-time preinit discovery)
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
4. Point Custota at the `magisk/` URL; take the OTA; on next boot you're rooted + locked.

## Recovery (if a boot fails)
- **Do NOT switch slots.** Reboot to bootloader.
- `fastboot flashing unlock` (works because OEM unlocking is enabled) → wipes → re-flash
  stock via the Android Flash Tool (<https://flash.android.com>) → start over.
- This is why backups matter: recovery costs data, not the device.

## Root-detection hiding (optional, DEVICE-tier only)
See the repo notes on Magisk fork choice. On the pixincreate fork: enable **Zygisk**, add
apps to the **DenyList**, and use a **Play Integrity Fix** module. STRONG stays unreachable.

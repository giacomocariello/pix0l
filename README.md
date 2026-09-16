# pix0l

Automated, self-hosted **rooted GrapheneOS** for the **Pixel 10 Pro Fold** (`rango`),
with a **relocked bootloader** (custom AVB key) and **seamless OTA updates** — built on
free CI, served from free hosting.

It stitches together existing components:

- **[avbroot](https://github.com/chenxiaolong/avbroot)** — patches the stock GrapheneOS
  OTA (adds Magisk to `init_boot`) and re-signs it with *your* AVB + OTA keys, so a
  bootloader locked to your key still passes verified boot. No AOSP build required.
- **[Custota](https://github.com/chenxiaolong/Custota)** — updater app that applies your
  re-signed A/B OTAs seamlessly while the bootloader stays **locked**.
- **[pixincreate/Magisk](https://github.com/pixincreate/Magisk)** — Magisk fork that fixes
  Zygisk on GrapheneOS (upstream Magisk's Zygisk does not work here).
- **GitHub Actions** (free, unlimited on public repos) builds; **GitHub Releases** hosts
  the OTA zips; **GitHub Pages** hosts the small Custota metadata.

## What this is (and isn't)

- **Goal:** root (for full backups, e.g. Neo Backup) + relocked verified boot + hands-off
  OTAs, landing at Play Integrity **DEVICE** tier (the most a non-Google-keyed OS can reach).
- **Not:** a way to pass **STRONG** integrity. Apps that require STRONG (e.g. Revolut) will
  not work — on stock *or* rooted GrapheneOS. That door is closed by hardware/Google policy.
- Verified boot after relock shows the **yellow** state with *your* key fingerprint — expected.

## Security model

Your `keys/` are the root of trust. They live only in your offline backup and in GitHub
**Actions secrets** — never in the repo. If they leak, your relock is worthless: rotate and
re-flash. The published OTAs are harmless (only a device locked to your AVB key trusts them).

## How the pipeline works

1. Daily (or on-demand) it reads the latest GrapheneOS `rango` `stable` version.
2. Downloads the stock OTA + `avbroot`/`custota-tool` (signatures verified against
   chenxiaolong's SSH key).
3. Patches: always a **rootless** flavor; a **magisk** flavor too once
   `MAGISK_PREINIT_DEVICE` is set (a one-time value read off your device).
4. Re-signs, generates Custota `.csig` + `rango.json`.
5. Publishes OTA zips to a Release tagged with the version; publishes metadata to Pages at
   `https://giacomocariello.github.io/pix0l/{rootless,magisk}/rango.json`.

## Setup

```sh
# 0. tools are vendored under .tooling/ (avbroot, custota-tool for macOS)
# 1. generate your keys (once) — back up keys/ offline afterwards
scripts/generate-keys.sh
# 2. create the public repo + push (see below), then:
scripts/set-secrets.sh
# 3. trigger the first (rootless) build
gh workflow run build.yml -R giacomocariello/pix0l
```

Then flash & relock the device, and enable Magisk — see **[docs/install.md](docs/install.md)**.

## Config (repo variables)

| Variable | Default | Purpose |
|---|---|---|
| `MAGISK_SOURCE` | `pixincreate/Magisk` | Magisk fork repo |
| `MAGISK_VERSION` | `v31.0-3` | Magisk release tag |
| `MAGISK_PREINIT_DEVICE` | *(unset)* | Per-device preinit partition; set it to enable the Magisk flavor |

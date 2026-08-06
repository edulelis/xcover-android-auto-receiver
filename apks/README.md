---
title: Sideloaded APK ledger
status: maintained
last_updated: 2026-08-06
---

# Sideloaded APK ledger

APK binaries are not committed to this repository. Before installing an APK, record its source, package identity, version, SHA-256 digest, signing certificate, purpose, and verification date here.

## Active public receiver launcher build: Open Headunit TPMS v0.3.0

| Field | Value |
| --- | --- |
| Purpose | Dedicated receiver with bounded TPMS capture, Android `HOME` role, native app drawer, and performance provisioning |
| Package | `com.andrerinas.headunitrevived.hfpslc` |
| Display label | `Open Headunit TPMS` |
| Version | `3.2.0-hfp-slc` (`versionCode=95`) |
| Upstream | [Open Headunit](https://github.com/andreknieriem/open-headunit), commit `581a55f26fe74b2c93eae5778ddcd683eb08b113` |
| Base patch | [`../patches/open-headunit-hfp-slc.patch`](../patches/open-headunit-hfp-slc.patch) |
| Incremental patch | [`../patches/open-headunit-tpms-pairing.patch`](../patches/open-headunit-tpms-pairing.patch) |
| Local build artifact | `tmp/release/v0.3.0/open-headunit-tpms-xcover-v0.3.0-debug.apk` |
| Public release | [`v0.3.0`](../../../releases/tag/v0.3.0) |
| Public asset | `open-headunit-tpms-xcover-v0.3.0-debug.apk` |
| APK SHA-256 | `c6703403548542bc80ad881f814fd1b6e6e22576742d8649f4aec391f7090f81` |
| Base patch SHA-256 | `5758bd9b46dc8355eccba5729d7227c43d6b385927d51965087a5d089c4c1ab1` |
| Incremental patch SHA-256 | `e4921c99e7766cd7a270851fc8e962df7ecaf2c663679d1aca9233bc2085e0eb` |
| Signing certificate | Android debug certificate: `C=US, O=Android, CN=Android Debug` |
| Certificate SHA-256 | `bc31e8db447636a30d2f1f97bd8ca190b110c33395d2321690a995171e72eac1` |
| Build date | 2026-08-06 |
| Current status | Exact public release candidate installed; local and installed hashes match; clean-patch tests/build, Android Auto connection/reconnection, and physical launcher routes verified |

The receiver is Android's default launcher. **Apps** opens a receiver-owned two-column drawer, with **System settings** pinned first and enabled launchable apps following alphabetically. Cards flow left-to-right and top-to-bottom; each card centers its icon and label as one group. The drawer header contains only a Back action, and Android's native Back behavior returns to the receiver home. No launcher or settings route shows a parked-use confirmation. One UI Home remains installed and enabled only for rollback. The idle bar shows no redundant ready label; `Connecting…` and `Return` are states of the Android Auto button itself.

The `githubDebug` artifact retains the established Android debug signing identity and package suffix, but its application manifest is intentionally non-debuggable. Android otherwise forces debuggable applications to the `verify` compiler filter and ignores their AOT output. Dedicated TPMS test surfaces use a separate build flag and remain available.

ART `speed` compilation and all three 0.5× animation scales were reapplied after the final installation. Physical checks covered equal-height bottom actions, the native drawer, centered card content, direct System Settings, the visible Back action, and Android Back return through drawer and Home. The exact `v0.3.0` candidate also completed Android Auto connection and reconnection after an app restart.

## Previous public receiver release: Open Headunit TPMS v0.2.0

| Field | Value |
| --- | --- |
| Purpose | Dedicated wireless Android Auto receiver with native HFP SLC fix and BLE TPMS integration |
| Package | `com.andrerinas.headunitrevived.hfpslc` |
| Display label | `Open Headunit TPMS` |
| Version | `3.2.0-hfp-slc` (`versionCode=91`) |
| Upstream | [Open Headunit](https://github.com/andreknieriem/open-headunit), commit `581a55f26fe74b2c93eae5778ddcd683eb08b113` |
| Base patch | [`../patches/open-headunit-hfp-slc.patch`](../patches/open-headunit-hfp-slc.patch) |
| Incremental patch | [`../patches/open-headunit-tpms-pairing.patch`](../patches/open-headunit-tpms-pairing.patch) |
| Local build artifact | `tmp/release/v0.2.0/open-headunit-tpms-xcover-v0.2.0-debug.apk` |
| Public release | [`v0.2.0`](../../../releases/tag/v0.2.0) |
| Public asset | `open-headunit-tpms-xcover-v0.2.0-debug.apk` |
| APK SHA-256 | `c46be61de0c99b94caac61e808a9697defb4bac7201f00c4cf0e8d8a1cb44b13` |
| Base patch SHA-256 | `5758bd9b46dc8355eccba5729d7227c43d6b385927d51965087a5d089c4c1ab1` |
| Incremental patch SHA-256 | `cded7c165e4b75ee7b0cb1ba912deefe330a5e48f2ccababcf5e0923da4299be` |
| Signing certificate | Android debug certificate: `C=US, O=Android, CN=Android Debug` |
| Certificate SHA-256 | `bc31e8db447636a30d2f1f97bd8ca190b110c33395d2321690a995171e72eac1` |
| Build and installation date | 2026-08-05 |
| Current status | Previous installed baseline and current public release; superseded locally by version code 95 |

### Verified behavior

- Completed HFP SLC, Bluetooth credential exchange, Wi-Fi Direct association, and Android Auto projection.
- Starts after boot and stable external-power events.
- Runs automatic Native Android Auto wake retries only while external power is present and cancels them on power removal.
- Keeps the explicit **Connect** action available while unplugged.
- Bounds the power-startup partial wake lock to ten seconds.
- Does not relaunch the home screen for every `SCREEN_ON` broadcast.
- Leaves USB device listening disabled by default.
- Suppresses non-actionable native Wi-Fi Direct toasts while keeping diagnostic logs.
- Exposes only the Android Auto action on the main home surface; CarPlay is not advertised.
- Retains the olive motorcycle image as the non-interactive visual anchor; the rejected receiver-status dashboard is absent.
- Uses `Android Auto` without a redundant `Wireless` qualifier on dedicated home and splash surfaces.
- Insets the adaptive Yamaha launcher mark to prevent Samsung icon-mask clipping.
- Provides BLE scanning, front/rear sensor assignment, and `BR/0x27A5` decoding.
- Uses PSI in the public UI while retaining bar internally for decoder math and thresholds.
- Shows a compact critical TPMS overlay during projection.
- Follows the Android locale, with English as the source and fallback language.
- Operational strings use generic receiver and phone roles instead of owner-specific labels.
- Restores wireless debugging at boot only after the one-time `WRITE_SECURE_SETTINGS` grant.
- Uses the physical side key (`keyCode 1015`) to disable application touch without stopping projection, audio, or the display.
- Keeps the locked indicator visible and shows a 1.2-second non-blocking confirmation when touch is restored.

### Verification record

- `:app:testGithubDebugUnitTest`: passed on 2026-08-05.
- `:app:assembleGithubDebug`: passed on 2026-08-05.
- Both repository patches were applied to a clean checkout before building the exact `v0.2.0` candidate.
- The exact candidate's package, update-compatible certificate, local and installed SHA-256, preserved preferences, and launch were verified on the physical XCover.
- A reversible Android battery-service power simulation verified that automatic retries stop after power removal and restart after power restoration; the startup wake lock released after ten seconds.
- Android Auto projection and reconnection after an app restart were verified with the exact candidate.
- The overnight unplugged discharge rate with `v0.2.0` remains pending measurement.
- Visual inspection: Android 15 emulator at 2400×1080 landscape and the physical XCover.
- Physical side-key lock/unlock and blocked home touch input: verified on the XCover.
- Projection activity touch interception: contract-tested; live projection interaction check pending.
- Language switching: Spanish and system-default restoration verified on the XCover.
- TPMS simulation: displayed over a live Google Maps projection and removed automatically after 12 seconds.
- Physical BLE sensor advertisements and real threshold behavior: pending sensor delivery.

### Theme context

The debug artifact contains the personal, non-commercial Yamaha/Tracer fair-use theme. It does not imply sponsorship, endorsement, or affiliation with Yamaha. The application label and operational copy remain generic.

## Rollback receiver: official Open Headunit 3.2.0

| Field | Value |
| --- | --- |
| Package | `com.andrerinas.headunitrevived` |
| Official file | `com.andrerinas.headunitrevived_3.2.0.apk` |
| Version | `3.2.0` (`versionCode=91`) |
| minSdk / targetSdk | 16 / 36 |
| Repository | <https://github.com/andreknieriem/open-headunit> |
| Release | <https://github.com/andreknieriem/open-headunit/releases/tag/v.3.2.0> |
| APK SHA-256 | `e3ad955cd28a058ce19503f70ea1feac033e24e877c135c5c2dbe61aced50cea` |
| Certificate | `CN=André Rinas, OU=Headunit Revived, O=Headunit Revived, L=Cologne, ST=NRW, C=DE` |
| Certificate SHA-256 | `615bc3c7a74839918d01517e49397f503a5473f89266af55a26d485c1e86155d` |
| Verified signature schemes | v1 and v2 |
| Verification date | 2026-08-03 |
| Current status | Installed but disabled; retained as rollback |

A temporary downgrade to 3.1.1 was reverted. The official package is back on 3.2.0 with its data preserved.

## Inactive experiment: HeadlessUnit 0.9.7

| Field | Value |
| --- | --- |
| Package | `com.stevenw.headlessunit.android` |
| Distributed file | `androidApp-release.apk` |
| Version | `0.9.7` (`versionCode=54`) |
| minSdk / targetSdk | 26 / 37 |
| Google Play listing | <https://play.google.com/store/apps/details?id=com.stevenw.headlessunit.android> |
| Developer distribution folder | <https://drive.google.com/drive/folders/1zgMZ9yEmU4uaTwPuQb564p3ExLRTHi8_> |
| APK SHA-256 | `17406c3f61019ba764468952f2c8e5f780e3c9db59dbba77554ccba3868dc361` |
| Certificate | `C=US, CN=Steven Wang` |
| Certificate SHA-256 | `97a629585e47b39f9b20038652cb15d3d9111b49c316f88e540572329aa07d35` |
| Verified signature scheme | v2 |
| Verification date | 2026-08-03 |
| Current status | Installed but not used by the verified architecture |

This path required a projector-mode companion application on the primary phone and is not part of the deployed solution.

## Removed experiment: AGAMA Car Launcher 5.0.5

AGAMA Car Launcher (`altergames.carlauncher`) was installed only for visual evaluation and removed on 2026-08-03. It is not an Android Auto receiver and was never set as the default launcher. Notification access granted during evaluation was revoked before removal.

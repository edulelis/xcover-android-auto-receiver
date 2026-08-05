---
title: Canonical installed state
status: current
last_verified: 2026-08-04
last_updated: 2026-08-05
audience: operators, maintainers, and LLM agents
---

# Canonical installed state

This file is the source of truth for what is currently installed, configured, verified, provisional, and pending. Historical snapshots and plans do not override it.

## Hardware and OS

| Item | State | Evidence level |
|---|---|---|
| Receiver | Samsung Galaxy XCover Pro `SM-G715U1` | Verified |
| Android / vendor UI | Android 13 / One UI 5.1 | Verified |
| Firmware / bootloader | `G715U1UEUKEXB2` | Verified in device inventory |
| Security patch | `2024-02-01` | Verified |
| Bootloader | locked; verified boot green; warranty bit 0 | Verified |
| Root | not installed | Verified |
| Projecting phone | Android phone; model intentionally withheld | Verified for the working session |
| Receiver orientation | fixed landscape | Configured and verified |

## Receiver software

| Item | State | Evidence level |
|---|---|---|
| Active app label | `Open Headunit TPMS` | Verified with `aapt` and on-device install |
| Active package | `com.andrerinas.headunitrevived.hfpslc` | Verified |
| Version | `3.2.0-hfp-slc`, version code 91 | Verified |
| Installed APK SHA-256 | `7f6dde4d7b6fa89dc3eb92e94e8c1937a557e89cd96fe1120a0826c66e1abbb1` | Public `v0.1.0` asset; verified from a clean patch application and from the installed package |
| Official Open Headunit | installed but disabled as rollback | Verified in cleanup record |
| HeadlessUnit | installed but disabled; not in the validated path | Historical/rollback |
| App default language | English base resources; system locale selected by default | Verified by resources and locale test |

See [`../apks/README.md`](../apks/README.md) for source, certificate, and rollback package details.

## Android Auto transport

| Capability | State |
|---|---|
| Bluetooth wake and HFP SLC | Verified |
| Android Auto Bluetooth messages 1/2/3 | Verified |
| Wi-Fi Direct group | Verified at 5 GHz with the XCover as Group Owner |
| Projection | Verified with Android Auto 17.0 on the tested phone |
| Measured app-restart reconnect | approximately 10 seconds |
| Cold boot reconnect | Verified |
| Second Samsung boot event deduplication | Verified |
| Static BSSID handling | Required on the tested Samsung build; value intentionally not stored |

## Power and maintenance

| Setting or behavior | Current state |
|---|---|
| Start on power connected | enabled; 1.5-second debounce |
| Wake lock | bounded to ten seconds |
| Secure-lock bypass | not implemented; only a no-credential lock screen can be dismissed |
| Stay awake while powered | enabled for all external power types |
| Unplugged screen timeout | 30 seconds |
| Unplugged idle | Light Doze then Deep Doze allowed |
| Manual brightness | 255 with Samsung Extra Brightness |
| Adaptive brightness / Attention | disabled for predictable behavior |
| Battery Protect | enabled |
| Automatic battery saver | 20% |
| Thermal limits | unchanged |
| Wireless ADB after boot | app may restore `adb_wifi_enabled=1` after one-time `WRITE_SECURE_SETTINGS` grant |
| Rain touch lock | programmable side key `keyCode 1015`; home interception verified on the physical XCover; projection path contract-tested |

## Dedicated home and copy

- **Installed:** the home shows Android Auto, TPMS, audio output role, settings, and the olive motorcycle image.
- The rejected clock, power, charge, and battery-temperature dashboard is not present in the installed build.
- Self Mode, USB, CarPlay, local OBD, and unrelated app shortcuts are hidden.
- Dedicated headers and connection progress use `Android Auto` without repeating `Wireless`.
- The adaptive launcher icon keeps the Yamaha mark within Android's safe area.
- UI base resources are English and device-neutral.
- Brazilian Portuguese and existing project locales remain available.
- `DedicatedCopyContractTest` enforces role-based public copy and the generic application label.
- Yamaha/Tracer imagery is enabled in the current build as a personal, non-commercial fair-use theme; it does not imply sponsorship, endorsement, or affiliation.
- The restored layout was verified at 2400×1080 on an Android 15 emulator and on the physical XCover.
- The programmable side key disables application touch without stopping Android Auto, audio, or the display. A second press restores touch; app process restart fails safe to unlocked input.

## TPMS

| Item | State |
|---|---|
| BLE scan and wheel assignment | Implemented and tested without physical sensors |
| Known decoder candidate | `BR` / service `0x27A5` |
| Physical LEEPEE/MotorCare compatibility | Pending |
| Display unit | PSI; temperature in °C |
| Internal threshold unit | bar |
| Reading freshness | expires after ten minutes |
| Overlay | silent, compact, dismissible, non-modal |
| Simulation | 12 seconds, visibly marked `TEST`, does not mutate telemetry |
| Low/high pressure thresholds | `≤ 1.8 bar` / `≥ 3.6 bar`, provisional |
| High temperature threshold | `≥ 80 °C`, provisional |

Do not treat provisional thresholds as motorcycle tire specifications. Calibrate them separately for front and rear tires after the physical sensors arrive and are compared with a known gauge.

## Disabled package strategy

Cleanup batches use `pm disable-user --user 0`, not removal. Matching rollback scripts re-enable every package. The active architecture preserves System UI, Settings, One UI Home, keyboard, Bluetooth, Wi-Fi, location, Play Services, OTA updater, Package Installer, and internal telephony/connectivity providers.

## Verified test set

- patched Open Headunit unit tests and `assembleGithubDebug`;
- HFP command parsing/order and optional codec negotiation;
- Native Android Auto projection and reconnect;
- landscape layout contracts and cold-start crash regression;
- power-connected wake and unplugged Doze behavior;
- TPMS parser, assignment, expiration, critical evaluation, localization coverage, and overlay contract;
- physical-device visual checks for the home and simulated TPMS alert;
- side-key `keyCode 1015`, home touch interception, and lock/unlock feedback on the physical XCover;
- application-wide and projection-activity touch-lock contract tests;
- Spanish per-app locale followed by return to the device's system locale.

## Open risks and pending validation

1. Validate music, navigation prompts, calls, and microphone with the real intercom.
2. Validate GPS and route resume over a prolonged ride.
3. Measure charging and device temperature under sunlight and navigation load.
4. Test real vehicle power insertion, removal, and brief ignition interruptions.
5. Capture a sanitized advertisement from the physical TPMS kit.
6. Confirm sensor identifier stability and packet format.
7. Calibrate front/rear pressure thresholds against a known gauge.
8. Repeat the touch-lock interception check during a live Android Auto projection.
9. Reassess the Yamaha/Tracer theme if the project's personal, non-commercial scope changes.

## Public repository privacy state

On 2026-08-05, the public default branch and the existing release tag were rewritten to an anonymized root history after device-specific evidence and identifying commit metadata were removed. A fresh public clone verified the sanitized tree and generic commit identity. No public forks or pull requests were present at that verification point.

The removed object identifiers are intentionally not recorded. They are unreachable from the published branch, tag, and a normal clone, although the hosting provider may temporarily retain unreachable objects for callers who already possess an old identifier. No credential or token exposure was identified. Server-side garbage collection and cached-view removal remain optional follow-up through the hosting provider's support process; no support request has been opened.

Repository ownership remains visible through the hosting platform by design. Removing that association would require transferring the project to a neutral account or organization and is separate from repository-content anonymization.

## Recovery entry points

- ADB discovery: `scripts/connect-wireless.sh <receiver-ip>`
- Package cleanup rollback: `scripts/rollback-cleanup-batch-*.sh`
- Power policy rollback: `scripts/rollback-power-baseline.sh` and `scripts/rollback-unplugged-sleep.sh`
- Boot/ADB rollback: `scripts/rollback-dedicated-boot.sh`
- Orientation rollback: `scripts/rollback-landscape.sh`
- Notification volume rollback: `scripts/rollback-silent-notifications.sh`
- Experimental app removal: `adb -s <xcover-serial> uninstall com.andrerinas.headunitrevived.hfpslc`

---
title: Initial device change plan and execution record
status: historical
created: 2026-08-03
last_updated: 2026-08-04
scope: SM-G715U1 cleanup and dedicated-receiver conversion
authority: historical record; use current-state.md for deployed state
---

# Initial device change plan and execution record

## Purpose

This document records the initial cleanup plan and the batches applied while converting the XCover Pro into a dedicated Android Auto receiver. It is not the current source of truth. Read [`current-state.md`](current-state.md) before using any value below.

Confirmed starting device: Samsung Galaxy XCover Pro `SM-G715U1`, Android 13, One UI 5.1, security patch `2024-02-01`.

Pre-change evidence was captured locally. Raw device inventories are intentionally excluded from the public repository.

## Safety model

- Disable optional packages for user 0; do not remove system APKs.
- Apply one small batch at a time.
- Keep an inverse script for every cleanup or settings script.
- Preserve boot, System UI, Settings, package installation, OTA, keyboard, Bluetooth, Wi-Fi, location, audio, and internal telephony services.
- Reboot and verify the receiver after each material batch.

## Cleanup batches

### Batch 01: independent consumer applications

Disabled categories:

- Facebook applications and installers;
- Microsoft Phone Link and OneDrive;
- Netflix and its promotional activator;
- Samsung Shop, Tips, Smart Switch, and migration helpers;
- Google TV, Meet, Drive, and Photos;
- ANT+ sample application;
- Samsung Game Launcher, Game Tools, Samsung Free, and the user manual;
- Samsung parental-care application.

Apply: [`../scripts/cleanup-batch-01.sh`](../scripts/cleanup-batch-01.sh)  
Rollback: [`../scripts/rollback-cleanup-batch-01.sh`](../scripts/rollback-cleanup-batch-01.sh)

### Batch 02: dedicated receiver

After native projection from the anonymized test phone was verified, these local applications were no longer part of the operating architecture:

- official Open Headunit and HeadlessUnit, retained disabled as rollback candidates;
- Play Store and Google Setup Wizard;
- local Maps, YouTube Music, Google Search/Assistant, and Android Auto.

Google Play Services and the functional experimental receiver package were preserved.

Apply: [`../scripts/cleanup-batch-02-receiver-only.sh`](../scripts/cleanup-batch-02-receiver-only.sh)  
Rollback: [`../scripts/rollback-cleanup-batch-02-receiver-only.sh`](../scripts/rollback-cleanup-batch-02-receiver-only.sh)

### Batch 03: optional Samsung features

Disabled categories:

- Bixby agent, voice wake-up, Bixby Vision, and Settings integration;
- AR Zone, AR Emoji, and Dressroom;
- Galaxy Themes client while preserving the system theme engine;
- Samsung Internet and Weather;
- Dynamic Lock Screen.

Samsung Modes and Routines, keyboard, base camera services, telephony internals, updater, System UI, security, and connectivity were preserved.

Apply: [`../scripts/cleanup-batch-03-samsung-optional.sh`](../scripts/cleanup-batch-03-samsung-optional.sh)  
Rollback: [`../scripts/rollback-cleanup-batch-03-samsung-optional.sh`](../scripts/rollback-cleanup-batch-03-samsung-optional.sh)

### Batch 04: HUD-only launcher surface

After confirming the XCover would not be used for SIM calls, contacts, messaging, or general phone tasks, the following user-facing applications were disabled:

- Chrome, Gmail, and YouTube;
- Contacts, Calendar, Phone, and Messages;
- Camera, Gallery, Clock, and My Files;
- Galaxy Store.

One UI Home, Settings, System UI, keyboard, OTA, Package Installer, Play Services, location providers, and internal telephony, Telecom, Bluetooth, and Wi-Fi components were preserved.

Apply: [`../scripts/cleanup-batch-04-hud-only.sh`](../scripts/cleanup-batch-04-hud-only.sh)  
Rollback: [`../scripts/rollback-cleanup-batch-04-hud-only.sh`](../scripts/rollback-cleanup-batch-04-hud-only.sh)

## Device configuration changes

### Power and screen baseline

The final configuration superseded the initial adaptive-brightness proposal:

- Battery Protect enabled when available;
- screen kept awake while any external power source is present;
- adaptive brightness disabled;
- manual brightness set to maximum, including Samsung Extra Brightness;
- 30-second screen timeout when truly unplugged;
- Attention/Adaptive Sleep disabled for predictable timeout;
- shorter Light Doze and Deep Doze entry while stationary and unplugged;
- Adaptive Battery, App Standby, and automatic restrictions preserved;
- battery saver scheduled at 20%.

Apply: [`../scripts/configure-power-baseline.sh`](../scripts/configure-power-baseline.sh), then [`../scripts/configure-unplugged-sleep.sh`](../scripts/configure-unplugged-sleep.sh)  
Rollback: [`../scripts/rollback-unplugged-sleep.sh`](../scripts/rollback-unplugged-sleep.sh), then [`../scripts/rollback-power-baseline.sh`](../scripts/rollback-power-baseline.sh)

The receiver also handles `ACTION_POWER_CONNECTED`. After a 1.5-second stability delay, it briefly acquires a wake lock, turns on the display, dismisses an unsecured keyguard, opens the receiver, and rearms native Android Auto. It does not bypass a PIN, password, or pattern. It does not rely on opening the app after every `SCREEN_ON` event.

### Public device identity

The public device and Bluetooth adapter name were customized locally. The historical custom value is intentionally omitted. The public script now defaults to the generic name `XCover Receiver` and accepts an operator-provided `XCOVER_PUBLIC_NAME` override. The Android model, serial, and internal identifiers are not changed.

Apply: [`../scripts/configure-device-name.sh`](../scripts/configure-device-name.sh)  
Rollback: [`../scripts/rollback-device-name.sh`](../scripts/rollback-device-name.sh)

This personal vehicle name is not a public application default.

### Orientation

System auto-rotation was disabled and the device was fixed in landscape (`user_rotation=1`). The receiver also requests landscape orientation.

Apply: [`../scripts/configure-landscape.sh`](../scripts/configure-landscape.sh)  
Rollback: [`../scripts/rollback-landscape.sh`](../scripts/rollback-landscape.sh)

### Notification audio

Only the Android notification stream was muted. Media, navigation, alarms, and call streams were preserved.

Apply: [`../scripts/configure-silent-notifications.sh`](../scripts/configure-silent-notifications.sh)  
Rollback: [`../scripts/rollback-silent-notifications.sh`](../scripts/rollback-silent-notifications.sh)

### Dedicated boot and wireless debugging

Samsung firmware disabled the Wireless debugging service on reboot while retaining the paired TLS key. The dedicated receiver was granted `WRITE_SECURE_SETTINGS` once through ADB so its boot receiver could restore `adb_wifi_enabled=1`. The unsecured lock screen was also disabled.

Apply: [`../scripts/configure-dedicated-boot.sh`](../scripts/configure-dedicated-boot.sh)  
Rollback: [`../scripts/rollback-dedicated-boot.sh`](../scripts/rollback-dedicated-boot.sh)

The rollback reenables the lock screen and revokes the privileged permission without intentionally terminating the current ADB session. No pairing code or private key is stored in the repository.

Use `scripts/connect-wireless.sh <receiver-ip>` from the repository root after reboot. It discovers the current `_adb-tls-connect._tcp` endpoint through mDNS and verifies model `SM_G715U1`; scripts must not hard-code a transient ADB port.

## Recorded outcomes on 2026-08-04

- Cleanup batches 02 and 03 were reapplied idempotently without breaking projection.
- Available memory with Android Auto active increased from approximately 995 MiB to 1.30 GiB.
- Receiver launch and automatic phone projection were verified after reboot.
- A second Samsung boot event did not replace the active projection.
- Maximum manual brightness and powered screen-on behavior were verified.
- Natural Light Doze while unplugged was verified.
- Batch 04 left 58 packages disabled in total while preserving the recovery surface.
- The receiver opened from a cold process in approximately 1.5 seconds before the final reboot test.
- Wireless debugging returned on a new port after reboot without a new pairing operation.

Post-optimization and HUD-only inventories were captured locally. Their anonymized outcomes are summarized above; raw dumps are intentionally excluded from the public repository.

## Remaining validation from the initial plan

- Repeat the complete power cycle with physical vehicle power rather than simulated battery state.
- Validate music, navigation, microphone, and calls with the real intercom.
- Validate TPMS BLE advertisements and thresholds with the purchased sensors.
- Measure temperature under full brightness, charging, navigation, and direct sun.
- Repeat boot, reconnection, and rollback tests after relevant OS or receiver updates.

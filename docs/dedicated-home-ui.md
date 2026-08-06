---
title: Dedicated receiver home UI
status: current with a personal non-commercial theme
last_verified: 2026-08-06
audience: UI maintainers, reviewers, and LLM agents
---

# Dedicated receiver home UI

## Outcome

The receiver home is a landscape motorcycle instrument surface rather than a generic application menu. It has three zones:

1. a personalized olive motorcycle image with no controls or fabricated telemetry;
2. front/rear TPMS pressure and temperature;
3. a bottom connection bar with real transport state and one Android Auto action.

Settings remain available through the gear button. Self Mode, USB, CarPlay, Exit, and local OBD are not shown on the dedicated surface. OBD was excluded because RPM and engine temperature already exist on the motorcycle display and would add distraction without a clear operational benefit.

`MainActivity` is Android's default `HOME` activity on the dedicated receiver. The riding surface remains focused on Android Auto and TPMS. A 48 dp **Apps** action in the bottom bar opens a native, two-column drawer owned by the receiver. **System settings** is pinned as the first drawer item, followed by enabled launchable apps in locale-aware alphabetical order, flowing left-to-right and then downward. Each card centers its icon and label as one group. The header intentionally contains only a 48 dp Back action: it and Android Back return to receiver home; Android Back from System Settings returns to this drawer first. One UI Home is not part of the daily route; it remains installed and enabled only for launcher rollback.

## Information hierarchy

The design follows patterns observed in motorcycle head units:

- pressure is the primary TPMS value;
- temperature is secondary;
- front and rear wheels remain visually separate;
- missing telemetry is neutral gray, never a fabricated value;
- strong color is reserved for exceptions rather than permanent decoration;
- the connection action remains large and reachable.

Current implementation:

- the motorcycle image is retained as the visual anchor; a receiver-health dashboard was tested and rejected as a visual regression;
- pressure in PSI;
- temperature in °C;
- `--.-` and `-- °C` when no fresh reading exists;
- olive accent `#6D7B3E` for identity and the primary action;
- red only for critical TPMS overlay conditions.

Design references:

- CHIGEE TPMS configuration/state: <https://support.chigee.com/portal/en/kb/articles/tpms-on-chigee-display>
- Carpuride W702 Pro front/rear pressure and temperature: <https://carpuride.com/cs/products/carpuride-w702-pro-wireless-portable-upgraded-dual-bluetooth-waterproof-ip67-motorcycle-stereo-with-intercom-function-compass-barometer>
- Google Design for Driving foundations: <https://developers.google.com/cars/design/design-foundations>

## Connection states and controls

The bottom bar is derived from the real transport state:

| State | UI behavior |
|---|---|
| `READY` | no adjacent status copy; the enabled `Connect` action is sufficient |
| `CONNECTING` | action temporarily disabled; wireless connection is being prepared |
| `CONNECTED` | action returns to the active projection |

The connection bar is 66 dp high. **Apps** and **Connect** are both 48 dp high and vertically centered, leaving 9 dp above and below. **Apps** is anchored 9 dp from the left edge and **Connect** 9 dp from the right. The motorcycle and TPMS zones are not moved or rescaled. No status region, dot, badge, or guideline remains: the large empty center separates the secondary launcher action from the primary Android Auto action.

The Android Auto button is the single visual source of connection state: `Connect` when idle, `Connecting…` while the handshake runs, and `Return` when a projection session is active. It uses a polite accessibility live region and state-specific descriptions. There is no visible `READY`/`PRONTO` label.

Opening **Apps**, opening **System settings**, and launching a drawer item do not show parked-use confirmation dialogs. The rain touch lock remains the synchronous safety boundary for the entire receiver, including the drawer.

A long press on the connection control opens the advanced Bluetooth device selector. Audio copy reads the `enable-audio-sink` setting and reports either `Played by the connected phone` or `Played by this device`.

Only Android Auto is shown. CarPlay was removed because the receiver does not implement it. The connection control was verified to initiate the Native Android Auto handshake after the redesign.

## Rain touch lock

The physical XCover programmable side key reports `keyCode 1015` and controls a process-local touch lock:

- first press: application touch is consumed across the home, settings, and Android Auto projection while a persistent `TOUCH LOCKED` indicator is visible;
- second press: touch is restored immediately and a non-blocking `TOUCH ENABLED` confirmation remains visible for 1.2 seconds;
- app process restart: input always returns unlocked to avoid an unrecoverable stale lock.

The lock does not turn off the display, pause projection, or alter Android's secure lock screen. It protects the application surface from rain-induced ghost touches; system UI gestures remain owned by Android.

The side-key mapping, immediate home-screen interception, persistent locked state, and transient release confirmation were verified on the physical XCover. The Android Auto projection activity uses the same synchronous guard and is contract-tested; repeat the interaction once during the next live projection session.

## Splash and identity

Android 13 displays a system splash before the app can render its controlled startup surface:

- Android 12+ system splash: olive Yamaha tuning-forks mark on black;
- controlled app splash: Yamaha mark, `OPEN HEADUNIT`, and `ANDROID AUTO`;
- adaptive icon: olive tuning-forks mark on black;
- home: small Yamaha identity in the header and the olive motorcycle image.

The Yamaha logo was derived from the transparent asset published by Yamaha Motor at <https://global.yamaha-motor.com/shared/img/rwd_identity.png>. The adaptive icon uses the tuning-forks mark inside Android's safe zone so Samsung's mask does not crop it.

These assets form the current personal, non-commercial Yamaha/Tracer fair-use theme. The theme does not imply sponsorship, endorsement, or affiliation with Yamaha. The application label and operational copy remain generic even though the visual theme is enabled.

Local assets:

- [`../artifacts/ui/assets/yamaha_motor_identity.png`](../artifacts/ui/assets/yamaha_motor_identity.png)
- [`../artifacts/ui/assets/yamaha_tuning_forks.png`](../artifacts/ui/assets/yamaha_tuning_forks.png)
- [`../artifacts/ui/assets/tracer_900_gt_green_hero.png`](../artifacts/ui/assets/tracer_900_gt_green_hero.png)

## Visual evidence

Current physical-device screenshots:

- [Installed launcher home on the physical XCover](../artifacts/ui/dedicated-home-launcher-vc95-20260806.png)
- [Native device-app drawer on the physical XCover](../artifacts/ui/dedicated-app-drawer-vc95-20260806.png)

- [First-run welcome on the physical XCover](../artifacts/ui/readme-first-run-en.png)
- [First-run WiFi connection choice on the physical XCover](../artifacts/ui/readme-first-run-wifi-en.png)
- [Current home on the physical XCover](../artifacts/ui/readme-home-en.png)
- [Native wireless setting on the physical XCover](../artifacts/ui/readme-android-auto-settings-en.png)
- [TPMS setup on the physical XCover](../artifacts/ui/readme-tpms-setup-en.png)
- [Touch lock active on the physical XCover](../artifacts/ui/readme-touch-lock-en.png)
- [English TPMS test alert on the physical XCover](../artifacts/ui/readme-tpms-alert-en.png)

Historical and design-development evidence:

- [Android system splash](../artifacts/ui/xcover-system-splash-yamaha-final.png)
- [Controlled app splash](../artifacts/ui/xcover-app-splash-yamaha-final.png)
- [Restored motorcycle home on emulator](../artifacts/ui/xcover-home-motorcycle-restored-emulator.png)
- [Current adaptive app icon](../artifacts/ui/xcover-app-icon-final.png)

Physical-device captures use the XCover in fixed landscape and contain no IP addresses, wireless credentials, peer identifiers, personal notifications, routes, or locations. The current launcher and drawer captures use the receiver's Brazilian Portuguese system locale; the separate onboarding set uses an English per-app locale that was returned to the Android system default after capture. The restored-motorcycle layout was also checked on an Android 15 emulator at 2400×1080. Primary targets remained large and no required control was clipped. The restored layout and both rain-lock states were verified on the physical device.

The dedicated header and connection progress say `Android Auto`; they do not repeat `Wireless` because the dedicated architecture already establishes that context. Technical settings retain wireless terminology where it distinguishes an actual transport mode.

## Startup orientation compatibility

Samsung may briefly inflate `layout-port/fragment_home.xml` before the activity's requested landscape orientation takes effect. Both home layout variants expose every ID bound by `HomeFragment`; dedicated-only fields remain hidden in portrait. `HomeLayoutContractTest` protects this binding contract.

After that compatibility fix, three consecutive cold starts completed without `FATAL EXCEPTION`, and `MainActivity` remained available until projection opened.

## Native AA notices

Technical group-creation and band-retry messages remain in `AppLog` but are not rendered as toasts over the receiver UI. The only Native AA toast retained requests a real user action when Wi-Fi is disabled.

## Reproduce and roll back

Apply the patches in order to the pinned Open Headunit commit:

1. [`../patches/open-headunit-hfp-slc.patch`](../patches/open-headunit-hfp-slc.patch)
2. [`../patches/open-headunit-tpms-pairing.patch`](../patches/open-headunit-tpms-pairing.patch)

Remove only the isolated build to return to the separately installed upstream application:

```sh
adb -s <xcover-serial> uninstall com.andrerinas.headunitrevived.hfpslc
```

## TPMS status

The setup flow, BLE scanner, assignment persistence, stale-reading expiration, and projection overlay are implemented. The known `BR` / `0x27A5` decoder remains a hypothesis until the physical LEEPEE/MotorCare sensors are captured. See [`tpms-integration.md`](tpms-integration.md).

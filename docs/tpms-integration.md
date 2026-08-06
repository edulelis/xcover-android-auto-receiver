---
title: BLE TPMS integration
status: candidate implementation; physical sensor validation pending
last_verified: 2026-08-05
audience: developers, testers, operators, and LLM agents
---

# BLE TPMS integration

## Goal

Read pressure and temperature directly from external LEEPEE/MotorCare motorcycle sensors without a cloud account, Play Store account, vendor app, or Android Bluetooth bond.

In this project, TPMS “pairing” means a local assignment from a BLE sensor identifier to `FRONT` or `REAR`. Sensors continue broadcasting BLE advertisements; the receiver does not establish an exclusive GATT connection.

## Implemented setup flow

1. Open **TPMS** from the receiver home. Opening this screen does not start a scan.
2. Select the highlighted **Front** or **Rear** step.
3. Keep only that sensor close to the receiver and activate it.
4. Select **Capture · 30 s**. Android requests **Nearby devices** only when this action needs it.
5. After the bounded capture stops, confirm **Use sensor** on the stable detected card.
6. Repeat for the other wheel, then select **Finish**.

This is BLE advertisement listening, not Android Bluetooth bonding and not an exclusive GATT connection. The target wheel is explicit; candidates preserve their first-seen order while their signal is refreshed; the capture ends automatically after 30 seconds. A sensor already assigned to the other wheel is identified and disabled. Replacement preserves the current assignment until the user confirms the new sensor.

Assignments are stored in package-private, device-protected `SharedPreferences`. They survive reboot and APK replacement and remain readable during locked boot.

## Protocol boundary

The first implemented decoder targets the publicly documented family:

- short BLE name: `BR`;
- 16-bit service: `0x27A5`;
- seven manufacturer bytes representing status, battery, temperature, pressure, and checksum;
- battery in tenths of a volt;
- signed integer temperature in °C;
- big-endian pressure converted by `(raw - 145) / 10` to PSI and then to bar internally.

Reference implementation: [andi38/TPMS](https://github.com/andi38/TPMS).

This family is compatible with advertisement-only sensors but does not prove that the purchased LEEPEE kit uses the same packet.

The normal pairing screen intentionally does **not** list generic compact manufacturer-data advertisements or rank cards by RSSI. A busy parking area contains too many unrelated BLE peripherals for that to be a usable or safe association flow.

Static inspection of the MotorCare 1.3.0 APK (package `com.chaoyue.motorcare`, SHA-256 verified against the distributor's published value) found its own 60-second automatic-bind route. Its code accepts a six-hex-digit sensor ID only when all of these agree:

- the advertised name starts `TPMS1` or `TPMS_1` for the front sensor, or `TPMS2` / `TPMS_2` for the rear;
- the raw advertisement has the matching decimal wheel marker `80` (front) or `81` (rear) at the vendor's fixed offset;
- the same six-digit ID occurs in the advertised name and packet.

The candidate implementation recognizes that identity pattern and stores the sensor ID locally rather than asking Android to create a Bluetooth bond. This is **static interoperability evidence only**: it is not proof that the purchased kit advertises the same packet, and it does not decode MotorCare pressure or temperature yet.

Selecting a recognized candidate writes one sanitized `TPMS selected candidate` line containing protocol classification, advertised name, service UUIDs, lengths, and raw packet bytes. The Bluetooth address is omitted. Capture that line after the physical sensor is observed:

```sh
adb -s <xcover-serial> logcat -d | rg 'TPMS selected candidate'
```

If the packet differs or no compatible sensor is captured, do not assign a random nearby device. Preserve the failed capture context and add a scoped diagnostic fixture before widening the normal filter. The available LEEPEE manual describes automatic association while a sensor is screwed onto the valve and identifies sensors individually: [LEEPEE Motorcycle TPMS Instruction Manual](https://manuals.plus/ae/1005004305938835).

## Bench activation before motorcycle installation

Use a spare Schrader/tubeless valve stem or a valve from an old inner tube as a small, stable test fixture. Screw on one sensor at a time, keep it next to the XCover, and use a hand pump or regulated inflator with a separate gauge to apply a modest, measured pressure. Start at roughly 1–2 bar and stay within the range printed on the actual sensor/manual. The manual published for this family lists a broad 1–13 bar operating range, but that is not a substitute for the kit's own label.

Do **not** blow into the sensor, disassemble it, press its valve core with an improvised object, or run it above its specified pressure. Mouth pressure is not controlled and can introduce moisture; an unknown external contact is not established as an activation switch. A pressure fixture also checks the exact seal and activation path that will be used on the motorcycle, while remaining off the bike.

For the arrival test, record only a minimal sanitized result:

1. Sensor label/position as `FRONT` or `REAR`, never a Bluetooth address.
2. Whether the 30-second capture found the expected identity and whether its ID remained stable after reopening the app.
3. The displayed pressure/temperature only after a decoder has been verified against the separate gauge.
4. A soapy-water leak check only after the sensor is finally installed on a valve.

## State model and stale data

| State | Meaning |
|---|---|
| `NO SENSORS` | no assignment is stored |
| `1/2 SENSORS` | exactly one wheel is assigned |
| `WAITING` | both IDs exist but no valid recent reading is available |
| `ACTIVE` | both wheels have valid readings received within ten minutes |

After ten minutes without a new advertisement, pressure and temperature return to `--.-` and `-- °C`. A stale value must never look current.

The scanner uses high intensity only during the user-started 30-second setup capture. With assigned sensors, the home and Android Auto projection use low-power scanning. No exclusive BLE connection is created.

## Android Auto overlay

The overlay belongs to the receiver and is rendered above the projection surface. It does not inject UI into the Android Auto protocol and does not require software on the projecting phone.

The alert is silent, compact, dismissible, and non-modal. It keeps navigation and audio active and displays only:

- a motorcycle-wheel vector with a small alert indicator;
- `FRONT` or `REAR`;
- PSI for a pressure condition or °C for a thermal condition.

Low pressure, high pressure, or high temperature remains in the accessibility description. The visible card does not repeat the word “alert” and does not include riding instructions.

The final card is 292 dp wide, uses a 46 dp icon, removes extra Android font padding between the two text rows, and retains a 48 dp dismiss target.

## Alert evaluation

Only a valid recent reading can produce an alert. Initial thresholds are:

- low pressure: `≤ 1.8 bar`;
- high pressure: `≥ 3.6 bar`;
- high temperature: `≥ 80 °C`.

These values are **provisional**, not tire specifications. Calibrate separate front/rear pressure limits after comparing the physical kit against a known gauge. An external valve sensor temperature is not the tire carcass temperature.

Dismissing a real condition acknowledges that same condition while it persists. It may alert again only after the wheel returns to normal and later re-enters a critical condition. Simultaneous front and rear conditions are queued.

## Safe simulation

With Android Auto projected, open receiver quick settings and choose **Settings → TPMS → Preview TPMS alert**. The simulation shows `FRONT`, `17 psi`, and a small `TEST` badge for 12 seconds. It does not change assignments, readings, or thresholds and emits no sound.

Debug builds can trigger the same path through ADB:

```sh
adb -s <xcover-serial> shell am start \
  -n com.andrerinas.headunitrevived.hfpslc/com.andrerinas.openheadunit.aap.AapProjectionActivity \
  --ez simulate_tpms_alert true
```

Visual evidence: [English compact landscape simulation](../artifacts/ui/readme-tpms-alert-en.png). The capture shows the visibly marked test card over the Android Auto startup surface; it is not evidence of an active route or physical sensor reading.

## Localization

English is the base/fallback resource. The app follows the Android system locale by default. Compact alert vocabulary is covered in Arabic, Czech, German, Spanish, Spanish (Spain), Hungarian, Italian, Japanese, Georgian, Korean, Dutch, Polish, Brazilian Portuguese, Romanian, Russian, Turkish, Ukrainian, Vietnamese, and Traditional Chinese.

A contract test requires all nine alert strings in every maintained locale directory. Physical-device verification temporarily selected `es-ES`, rendered `DELANTERO / PRUEBA / 17 psi`, and returned to the system `pt-BR` locale without reinstalling.

## Completed validation without physical sensors

- preserves all seven manufacturer bytes during advertisement parsing;
- decodes public fixture `0303A5270308425208FF281D130105A376` as 11.6 psi (about 0.80 bar), 19 °C, and 2.9 V;
- handles negative signed temperatures;
- rejects truncated packets and generic manufacturer packets that lack a TPMS protocol signature;
- recognizes the static MotorCare automatic-bind identity shape while keeping its telemetry unsupported;
- bounds a setup capture to 30 seconds, preserves candidate order, and uses diffed cards rather than a continuously re-sorted list;
- prevents one sensor from occupying both wheel slots;
- advances deterministically from front to rear and finishes at `2/2`;
- exposes visible recovery for denied permission, disabled Bluetooth, paused scan, and scanner failure;
- expires readings after ten minutes;
- covers landscape and temporary portrait binding contracts;
- covers low/high pressure, high temperature, normal, stale, and simultaneous states with unit tests;
- validates all compact alert locales with a contract test;
- verifies the 12-second overlay simulation on emulator and physical XCover without ending projection;
- verifies the final compact PSI layout on the physical XCover.

## Pending physical-kit validation

1. Confirm the LEEPEE/MotorCare advertised name, services, wheel marker, identifier, and packet.
2. Confirm identifier stability after sleep, battery replacement, and receiver reboot.
3. Prove the bench activation fixture before motorcycle installation.
4. Measure stationary and moving transmission intervals.
5. Compare pressure against a known gauge.
6. Add an isolated MotorCare telemetry decoder and regression fixture only after the packet is captured.
7. Calibrate separate front and rear thresholds.
8. Validate slow leak, rapid leak, low battery, and missing-sensor behavior.
9. Check valve clearance and leaks with soapy water after installation.

## Reproduce the code

Starting from upstream Open Headunit commit `581a55f26fe74b2c93eae5778ddcd683eb08b113`:

```sh
git apply /path/to/xcover/patches/open-headunit-hfp-slc.patch
git apply /path/to/xcover/patches/open-headunit-tpms-pairing.patch
ANDROID_HOME=/path/to/Android/sdk ./gradlew \
  :app:testGithubDebugUnitTest \
  :app:assembleGithubDebug
```

# XCover Dedicated Receiver — Agent Operating Manual

This file applies to the entire repository. It defines how human and automated agents must work on the XCover receiver project. It is an operating policy, not a substitute for the canonical installed-state record.

Last reconciled with the maintained documentation: **2026-08-05**.

## 1. Mission

Convert a Samsung Galaxy XCover Pro into a reliable, dedicated wireless Android Auto receiver for a motorcycle and, secondarily, a car. The receiver must be:

- safe to operate while parked and resistant to accidental input while riding;
- automatic at power-on and conservative at power-off;
- fast, legible, recoverable, and thermally responsible;
- independent of a Play Store account on the receiver;
- usable without root, a USB Android Auto dongle, or a companion application on the projecting phone;
- maintainable through reproducible patches, documented device configuration, and explicit rollback.

Navigation, media, calls, voice, and most notifications originate on the projecting phone. The XCover is a receiver, display, local input surface, and BLE TPMS host.

## 2. Priority order

When requirements conflict, use this order:

1. Riding and physical safety.
2. Reliable projection and automatic recovery.
3. Thermal, water, vibration, charging, and battery protection.
4. Correct power-on and power-off behavior.
5. Large targets, strong contrast, short copy, and low visual complexity.
6. Reproducibility, evidence, and rollback.
7. Optional features and visual novelty.

Never trade reliability or safety for feature count, branding, animation, or speculative telemetry.

## 3. Sources of truth and reading order

Before changing anything, read the documents relevant to the task in this order:

1. `AGENTS.md` — agent behavior, safety rules, and required workflow.
2. `README.md` — project entry point, daily operation, recovery, build, and rollback.
3. `docs/user-guide.md` — complete public installation, first connection, provisioning, troubleshooting, and rollback.
4. `docs/current-state.md` — canonical installed state, verified facts, public repository privacy state, provisional values, and open risks.
5. The owning feature document under `docs/`:
   - `docs/android-auto-xcover-only.md` for Android Auto transport and HFP/Wi-Fi Direct;
   - `docs/tpms-integration.md` for BLE TPMS;
   - `docs/dedicated-home-ui.md` for receiver UI, rain lock, and visual evidence;
   - `docs/copy-guidelines.md` for public copy and localization.
6. `apks/README.md` — APK provenance, version, signing certificate, hash, and rollback packages.
7. `docs/initial-change-plan.md` — historical investigation and execution record only.
8. `artifacts/device-snapshots/` — local-only raw evidence policy; raw inventories are ignored and never published.

If documents conflict, prefer the higher-authority maintained source and correct the stale lower-authority file in the same change. For mutable deployed facts, `docs/current-state.md` takes precedence over this manual.

Use the repository status vocabulary precisely:

- **Verified**: observed in a named environment — physical receiver, emulator, or automated test — with the environment stated beside the claim.
- **Configured**: set on the receiver but not necessarily exercised end to end.
- **Pending**: required validation has not been completed.
- **Provisional**: implemented but awaiting calibration or hardware confirmation.
- **Historical**: accurate for a dated past state, not current guidance.
- **Rejected**: evaluated and intentionally excluded from the active architecture.

Do not describe a plan, build candidate, emulator result, or configuration write as physically verified.

## 4. Current deployed baseline

Always confirm mutable details in `docs/current-state.md` before acting. The known baseline is:

- Receiver: Samsung Galaxy XCover Pro, model `SM-G715U1`.
- Home-LAN address: environment-specific; resolve it at runtime and never assume a public default.
- OS: Android 13, One UI 5.1.
- Orientation: fixed landscape.
- Role: dedicated receiver with no personal user data that requires preservation.
- Active package: `com.andrerinas.headunitrevived.hfpslc`.
- Active label: `Open Headunit TPMS`.
- Active version line: `3.2.0-hfp-slc`, version code 91.
- Projecting phone used for validation: Android phone; model intentionally withheld from public records.
- Root: absent and must not be assumed.
- Bootloader: locked in the last verified inventory.
- Upstream source: Open Headunit commit `581a55f26fe74b2c93eae5778ddcd683eb08b113`.
- Official Open Headunit package: installed but disabled as a separate rollback path.
- HeadlessUnit: installed but disabled; not part of the validated architecture.

Never copy an APK hash from this file. Read the active value from `docs/current-state.md` and `apks/README.md`, then verify the actual local and installed files.

## 5. Authorization boundary

The user has authorized the following actions on the dedicated XCover receiver when required by an in-scope task:

- read-only ADB diagnostics and sanitized inventory;
- application installation and replacement;
- application data cleanup when necessary and explicitly relevant;
- reversible package disabling;
- Android settings changes for the dedicated receiver role;
- launch, stop, and test the receiver application;
- reboot and post-reboot validation.

This standing authorization does **not** include:

- factory reset;
- bootloader unlock;
- partition, boot image, modem, recovery, or firmware flashing;
- root or Magisk installation;
- Knox removal, warranty-bit changes, or service-tool/test-point procedures;
- ROM replacement;
- Device Owner provisioning;
- destructive removal of broad system components;
- mutations on the projecting phone unless the user explicitly authorizes them for the current task.

Treat any action in the second list as a new authorization boundary. Stop and request explicit direction before performing it.

## 6. Validated architecture

The deployed path is software-only:

1. Bluetooth wakes the projecting phone.
2. The receiver performs the Android Auto wireless HFP Service Level Connection.
3. Android Auto Bluetooth credential messages are exchanged.
4. The XCover creates and owns a 5 GHz Wi-Fi Direct group.
5. The projecting phone joins that group.
6. Open Headunit renders projection and handles local input.
7. The receiver independently scans BLE TPMS advertisements and may draw a local alert over projection.

The HFP patch completes this sequence when supported by the phone:

```text
AT+BRSF=156
AT+BAC=1,2
AT+CIND=?
AT+CIND?
AT+CMER=3,0,0,1
```

`AT+BAC=1,2` is conditional on advertised codec negotiation support. Do not log raw HFP responses because they may contain personal call or network state.

The validated receiver settings use:

- connection mode: **WiFi**;
- discovery mode: **Native**;
- receiver-owned 5 GHz Wi-Fi Direct;
- a static BSSID matching the active group interface on the tested Samsung firmware.

Do not add a dongle, root requirement, or projecting-phone companion app to the primary architecture without a new explicit decision and evidence.

## 7. Repository layout and ownership

- `README.md`: public entry point, quick start, daily use, recovery, build, and rollback.
- `docs/user-guide.md`: end-to-end public installation, connection, operation, provisioning, troubleshooting, and rollback.
- `docs/`: canonical state, technical decisions, UI, copy, TPMS, and historical records.
- `scripts/`: idempotent device inventory/configuration and matching rollback scripts.
- `patches/open-headunit-hfp-slc.patch`: base Android Auto HFP SLC patch.
- `patches/open-headunit-tpms-pairing.patch`: incremental dedicated-receiver, UI, TPMS, power, localization, and rain-lock patch.
- `artifacts/device-snapshots/`: policy for local-only raw inventories; public evidence belongs in minimal English summaries.
- `artifacts/ui/`: sanitized screenshots and visual assets.
- `apks/README.md`: APK metadata ledger; APK binaries are not repository source.
- `tmp/apks/`: local build artifacts only; do not treat them as versioned source.

The repository root may be present without Git metadata. Do not assume `git status` is available. Preserve all existing files as user-owned. Use a separate temporary clone for upstream Open Headunit source work and for patch verification.

Do not place an entire upstream Open Headunit checkout inside this repository. The two patches are the reproducible source-of-truth for the customized application.

## 8. Required workflow for every change

### 8.1 Understand before mutating

1. Read the relevant authority documents.
2. Inspect existing scripts, patches, and evidence before inventing a new path.
3. Classify the task as read-only diagnosis, device configuration, app implementation, documentation, or deployment.
4. Identify what is already verified and what remains provisional or pending.
5. Preserve unrelated existing changes and artifacts.

### 8.2 Capture state before the first mutation

For a new device change set:

1. Resolve and verify the ADB target.
2. Run a sanitized inventory.
3. Store it locally under `artifacts/device-snapshots/` with a timestamp and a short purpose suffix when useful; raw `*.txt` inventories are Git-ignored.
4. Confirm battery, temperature, charging, storage, foreground activity, Wi-Fi, Bluetooth, and the active package before risky changes.

Do not create redundant snapshots for every read-only command, but always capture one before the first mutation in a materially new batch.

### 8.3 Apply small, reversible batches

Maintain explicit categories:

- **keep**: required system and receiver components;
- **disable**: optional packages, with reason and inverse command;
- **install**: source, version, purpose, permissions, certificate, and SHA-256;
- **configure**: previous value, new value, verification, and rollback;
- **evaluate**: insufficient evidence; do not mutate yet.

After each batch, verify the affected behavior and basic device health. Reboot before calling a cleanup or boot-policy batch stable.

### 8.4 Close the loop

1. Run the narrowest meaningful automated checks.
2. Run the full app test/build checks when application behavior changed.
3. Reproduce the build from clean patches when the incremental patch changed.
4. Install only after confirming the target model.
5. Verify the installed package identity and hash.
6. Exercise the physical behavior in proportion to risk.
7. Update canonical state, the owning feature document, the APK ledger, and evidence.
8. Leave the receiver in a usable state: app open when appropriate, touch unlocked, Bluetooth/Wi-Fi restored, and no diagnostic screen left in front.

## 9. ADB connection playbook

### 9.1 Preferred discovery

Use:

```sh
scripts/connect-wireless.sh <receiver-ip>
```

The script discovers `_adb-tls-connect._tcp`, removes stale sessions, and verifies the XCover model. The Wireless debugging TLS connection port changes when Wireless debugging or the device restarts.

When manual discovery is necessary:

```sh
adb mdns services
adb devices -l
```

If both a numeric address and an mDNS serial refer to the XCover, prefer the explicit numeric `<ip>:<port>` serial for mutations. Never target an unverified first entry from `adb devices`.

### 9.2 Pairing and connection

Pair only with the temporary pairing port shown by Android:

```sh
adb pair <ip>:<pairing-port>
adb connect <ip>:<connection-port>
```

The pairing port and connection port are different. Never record the six-digit pairing code. Confirm the computer fingerprint on the device.

Developer options do not imply TCP port 5555. Do not assume `:5555` unless an already USB-authorized session explicitly ran `adb tcpip 5555` for that session.

Wireless ADB normally disables after reboot. The application may restore `adb_wifi_enabled=1` after its one-time `WRITE_SECURE_SETTINGS` grant, but the TLS connection port still changes and must be rediscovered.

### 9.3 Required target check

Before every install, package mutation, reboot, or settings batch:

```sh
adb -s <serial> get-state
adb -s <serial> shell getprop ro.product.model
adb -s <serial> shell getprop ro.build.version.release
```

The model must be `SM-G715U1`. Stop if the serial is ambiguous, offline, unauthorized, or points to the projecting phone.

### 9.4 USB notes

USB-C charging does not prove an ADB data connection. A charge-only cable, port mode, authorization state, or host-role conflict may prevent USB debugging. Do not change the validated wireless architecture merely because a particular cable provides only charging.

## 10. Sanitized device inventory

Prefer `scripts/inventory.sh`. Capture at minimum:

- manufacturer, model, Android, One UI, SDK, build, firmware, and security patch;
- ADB transport type without the endpoint, plus bootloader/verified-boot state when queryable;
- device policy summary without account data;
- battery level, health, charging source, temperature, and Battery Protect;
- memory and storage;
- orientation, brightness mode/value, timeout, attention, and stay-awake settings;
- Wi-Fi, Bluetooth, and location capability without network or peer identifiers;
- launchers, user-installed packages, disabled packages, and relevant receiver settings;
- active package/version and foreground activity.

Never collect or store:

- accounts, contacts, call logs, messages, calendars, or notification contents;
- saved Wi-Fi networks, SSIDs, passphrases, or Wi-Fi Direct credentials;
- Bluetooth MAC addresses or peer identities;
- BSSIDs;
- pairing codes, ADB private keys, tokens, or application data;
- precise location or unsanitized map content.

Raw inventories are local-only and must not be committed. Publish only a minimal English interpretation with transport endpoints, hardware serials, peer identities, and unique device details removed.

## 11. Package and Android configuration rules

Prefer reversible disablement:

```sh
adb -s <serial> shell pm disable-user --user 0 <package>
adb -s <serial> shell pm enable <package>
```

Do not use `pm uninstall --user 0` as the first cleanup method. Do not clear application data unless the task genuinely requires it; APK replacement with `adb install -r` should preserve receiver settings and TPMS assignments.

Never disable:

- System UI or Settings;
- One UI Home or the active launcher;
- the active keyboard;
- Bluetooth, Wi-Fi, location, or their framework providers;
- Package Installer;
- emergency functionality;
- OTA updater;
- internal telephony/connectivity providers;
- Google or Samsung services required by Android Auto, location, package management, or the selected architecture.

Use the numbered cleanup scripts in order and use their matching rollback scripts. Do not invent an aggressive debloat list from package names alone.

## 12. Reproducible application build

### 12.1 Toolchain

The verified build uses:

- upstream Open Headunit commit `581a55f26fe74b2c93eae5778ddcd683eb08b113`;
- Android SDK 36;
- Android NDK `29.0.14206865`;
- the Gradle wrapper from upstream.

### 12.2 Build from canonical patches

Use an external or temporary working directory:

```sh
git clone https://github.com/andreknieriem/open-headunit.git
cd open-headunit
git checkout 581a55f26fe74b2c93eae5778ddcd683eb08b113
git apply /absolute/path/to/xcover/patches/open-headunit-hfp-slc.patch
git apply /absolute/path/to/xcover/patches/open-headunit-tpms-pairing.patch
ANDROID_HOME=/path/to/Android/sdk \
ANDROID_SDK_ROOT=/path/to/Android/sdk \
./gradlew :app:testGithubDebugUnitTest :app:assembleGithubDebug
```

Apply patches only in that order. The second patch is intentionally relative to upstream plus the HFP base patch.

### 12.3 Patch ownership

- Change `open-headunit-hfp-slc.patch` only for the minimal HFP SLC base behavior or its focused tests.
- Put dedicated receiver behavior, power integration, Android Auto refinements, TPMS, UI, copy, localization, assets, and rain lock in `open-headunit-tpms-pairing.patch`.
- Preserve upstream license and attribution files.
- Include binary assets with a binary-capable Git diff.
- Do not hand-edit large generated patch hunks when a source-tree edit and regeneration is safer.

### 12.4 Regenerate the incremental patch safely

1. Create a fresh temporary clone at the pinned upstream commit.
2. Apply `open-headunit-hfp-slc.patch`.
3. Record that state as a temporary local baseline commit.
4. Copy the intended modified `app/` tree into the temporary clone, excluding build outputs.
5. Stage all intended changes.
6. Generate the incremental patch with:

```sh
git diff --cached --binary --full-index HEAD > open-headunit-tpms-pairing.patch
```

7. Create another fresh clone.
8. Apply the base patch and the regenerated incremental patch.
9. Run the full unit-test and assemble commands from the fresh clone.
10. Replace the repository patch only after clean application and build succeed.

This clean-patch build, not a successful build from a dirty development tree, is the reproducibility proof.

## 13. APK provenance, installation, and verification

### 13.1 Before installation

1. Capture or confirm the pre-mutation snapshot.
2. Build from clean patches.
3. Record the package, label, version, source commit, purpose, certificate, and SHA-256 in `apks/README.md`.
4. Confirm the target model again.

Compute the local digest:

```sh
shasum -a 256 <apk>
```

Inspect package metadata and signing certificate with Android build tools such as `aapt`, `apkanalyzer`, and `apksigner`. The current experimental package uses the recorded Android debug certificate; do not silently introduce a new signing identity.

### 13.2 Install without clearing settings

```sh
adb -s <serial> install -r <apk>
```

After installation, start the launcher activity without changing auto-start settings:

```sh
adb -s <serial> shell monkey \
  -p com.andrerinas.headunitrevived.hfpslc \
  -c android.intent.category.LAUNCHER 1
```

An install restarts the application process. That intentionally resets the rain touch lock to unlocked but preserves application preferences when `-r` succeeds.

### 13.3 Verify the installed artifact

Check version and path:

```sh
adb -s <serial> shell dumpsys package \
  com.andrerinas.headunitrevived.hfpslc
adb -s <serial> shell pm path \
  com.andrerinas.headunitrevived.hfpslc
```

Hash the installed base APK without printing binary data:

```sh
installed_path=$(adb -s <serial> shell pm path \
  com.andrerinas.headunitrevived.hfpslc | \
  sed -n 's/^package://p' | tr -d '\r')
adb -s <serial> exec-out cat "$installed_path" | shasum -a 256
```

The installed digest must match the ledger artifact. Update `docs/current-state.md` only after this comparison succeeds.

Do not use `pm clear` or uninstall/reinstall merely to fix a launch problem; that would erase receiver preferences and TPMS assignments.

### 13.4 Public APK releases

APK binaries must not be committed to Git history. Publish them as versioned GitHub Release assets that project policy treats as immutable, with `SHA256SUMS.txt`, `APK-METADATA.txt`, and committed English release notes under `docs/releases/`.

Follow `docs/release-process.md`. Use `scripts/build-release-apk.sh` for the clean pinned-source build, install and exercise that exact candidate on the target receiver, finalize its evidence, and use `scripts/publish-github-release.sh` only after source, patches, documentation, and release notes are committed and pushed. Never upload or commit the private debug keystore. Never overwrite a published release asset or move a published tag for an ordinary correction; issue a new version instead. A user-authorized privacy purge is the only exception and must remove the exposed data from every public branch and tag.

## 14. Android Auto recovery and diagnostics

The two locally fixed failure classes are:

1. incomplete HFP SLC;
2. an incorrect Wi-Fi Direct BSSID source on the tested Samsung firmware.

If projection does not start:

1. Confirm Bluetooth and Wi-Fi are enabled on both devices.
2. Confirm the phone remains paired with the XCover in Android Bluetooth settings.
3. Confirm receiver mode **WiFi** and discovery mode **Native**.
4. Restart only the receiver app and allow the normal reconnect interval.
5. Distinguish HFP failure from Wi-Fi Direct association failure in sanitized logs.
6. If HFP completes but the phone does not join Wi-Fi Direct, inspect the active group interface:

```sh
adb -s <serial> shell ip addr show dev p2p-wlan0-0
```

7. Compare its `link/ether` value with the configured static BSSID without storing either value in the repository.
8. If `p2p-wlan0-0` is absent, identify the active Wi-Fi Direct group-owner interface from `ip -o addr show`; never use an arbitrary `p2p-` interface.
9. Save a corrected value only when evidence shows a mismatch, then force-stop and reopen the receiver app.

Do not expose non-actionable group creation, retry, or band-selection diagnostics as toasts. Keep them in sanitized application logs. A user-facing notice is appropriate only when the user must act, such as enabling Wi-Fi.

Successful video projection alone does not validate audio. Test music, navigation prompts, calls, microphone, A2DP, HFP, and AVRCP with the real intercom before declaring the audio topology ready.

## 15. Startup, power, charging, and sleep policy

### 15.1 External power present

- Wake the display and launch or recover the receiver after a stable power event.
- Debounce power connection for 1.5 seconds to reject ignition transients.
- Keep the display awake using Android's powered stay-awake setting.
- Use manual brightness 255 and Samsung Extra Brightness as configured.
- Use only a bounded ten-second wake lock during power-connected startup.

The display-awake policy depends on external power state, not whether the battery is actively accepting charge. Battery Protect may stop charging near its limit while external power remains present; the screen must still stay awake.

### 15.2 External power absent

- Use a 30-second screen timeout.
- Permit Light Doze followed by Deep Doze.
- Do not keep the display awake through an unconditional application flag.
- Do not create services or alarms that defeat idle without a measured need.

### 15.3 Lock-screen boundary

Power automation may wake the screen and dismiss only a lock screen with no secure credential. It must never bypass a PIN, password, pattern, biometric, or Android security policy.

Do not create redundant `SCREEN_ON` auto-start loops. The app already starts after boot and stable external-power events; it must not relaunch its home Activity over an active projection.

### 15.4 Thermal and battery rules

- Keep Samsung thermal limits unchanged.
- Keep Battery Protect enabled when practical.
- Preserve the removable battery as a power buffer.
- Do not assume operation without the battery is safe.
- Measure battery temperature under charging, full brightness, navigation, and direct sunlight.
- Use surge-protected vehicle power, strain relief, and weather protection.

## 16. Rain touch lock

The XCover programmable side key reports `keyCode 1015` in the application.

Required behavior:

- first press: synchronously consume application touch and show a persistent `TOUCH LOCKED` indicator;
- second press: restore touch immediately and show `TOUCH ENABLED` for 1.2 seconds;
- keep Android Auto projection, audio, and the display running in both states;
- keep the state process-local so an app crash, process death, or APK replacement always returns unlocked;
- toggle on key release so repeated key-down events from a long press do not toggle repeatedly;
- keep the key debugger able to observe the physical code while its debugger surface is visible.

Touch rejection must occur synchronously in Activity event dispatch, not only after an asynchronously rendered overlay becomes visible. Protect:

- normal application activities derived from `BaseActivity`;
- projection activities derived from `SurfaceActivity`;
- `AapProjectionActivity`, which has its own touch dispatch path.

The full-screen indicator overlay is useful feedback but is not the only correctness boundary. Test the race by sending `1015` and immediately tapping a known control with no artificial delay. The control must not activate.

This feature blocks touch delivered to the application. Android owns system bars, notification shade, hardware power, and other global gestures. Do not claim OS-global touch suppression without a separate verified mechanism.

Current evidence verifies the key mapping, home interception, persistent lock feedback, and release feedback on the physical XCover. The projection activity is contract-tested; repeat the physical interaction during a live Android Auto projection before upgrading that status to physically verified.

## 17. BLE TPMS policy

### 17.1 Pairing model

Treat TPMS setup as a local mapping from BLE sensor identifier to `FRONT` or `REAR`, not Android Bluetooth bonding. Advertisement-only sensors are not exclusive to one phone and should not require a cloud account, Play Store account, or vendor app.

Assignments live in package-private device-protected preferences and should survive reboot and `adb install -r`.

### 17.2 Protocol boundary

The implemented decoder candidate is provisional:

- short name `BR`;
- service `0x27A5`;
- seven manufacturer bytes;
- pressure and temperature decoding documented in `docs/tpms-integration.md`.

Do not claim physical LEEPEE/MotorCare compatibility until sanitized advertisements from the purchased kit are captured and decoded.

### 17.3 Data integrity

- Never fabricate pressure, temperature, voltage, signal, or sensor presence.
- Render missing pressure as `--.-` and missing temperature as `-- °C`.
- Expire readings after ten minutes without a fresh advertisement.
- Keep PSI as the public pressure unit and bar as the current internal threshold unit.
- Treat external sensor temperature as sensor temperature, not tire-carcass temperature.
- Never allow one identifier to occupy both wheel slots.

### 17.4 Alerts

Real alerts must be silent, compact, dismissible, queued, and non-modal over Android Auto. Visible copy contains only:

- `FRONT` or `REAR`;
- the relevant PSI or °C value;
- a small `TEST` badge only during simulation.

Do not add riding instructions or redundant words such as `Alert` to the visible card. Preserve the full condition in accessibility copy.

Current threshold values are provisional:

- low pressure: `≤ 1.8 bar`;
- high pressure: `≥ 3.6 bar`;
- high temperature: `≥ 80 °C`.

Never present these as Yamaha or tire-manufacturer specifications. Calibrate front and rear separately against the physical kit and a known gauge.

### 17.5 Simulation

Simulation must be visibly marked, time-bounded, and isolated. It must not mutate assignments, readings, acknowledgements, or thresholds. The current preview lasts 12 seconds.

## 18. Dedicated UI and interaction policy

The dedicated landscape home has three operational zones:

1. the olive motorcycle image as a non-interactive visual anchor;
2. front/rear TPMS pressure and temperature;
3. one Android Auto connection/return action with real transport state.

Settings remain available through a single gear action.

Do not restore the following to the dedicated home:

- Self Mode;
- USB mode;
- CarPlay, which is unsupported;
- Exit controls;
- local OBD telemetry;
- unrelated application shortcuts;
- the rejected clock, external-power, charge, and battery-temperature dashboard.

RPM and engine temperature already exist on the motorcycle display; local OBD was rejected as distraction without a clear benefit. Do not add telemetry merely because it is technically available.

Use the olive accent `#6D7B3E` for identity and primary action. Reserve red for actual critical TPMS state. Keep primary touch targets large, landscape-safe, and readable in daylight.

Any material UI change requires:

- comparison against the current accepted screenshot;
- emulator or device rendering at the target 2400×1080 landscape dimensions;
- a cold-start check for Samsung's brief portrait-layout inflation path;
- accessibility basics and target-size review;
- a sanitized screenshot under `artifacts/ui/`.

## 19. Public copy and localization

Maintained documentation and Android base resources are English-first. English is the source and fallback language; English-first does not mean English-only.

Public UI copy must be generic and role-based:

- use `phone` or `connected phone`, not a phone model;
- use `this device` or `receiver`, not `XCover`;
- use `Android Auto`, not redundant `Wireless Android Auto`, on dedicated surfaces;
- use `Played by the connected phone` or `Played by this device` for audio role;
- use `Set up sensor` or `Use sensor` for BLE assignment rather than Android `pairing` when no bond exists.

Do not put user-facing English literals directly in Kotlin or XML layouts. Add resources to `values/strings.xml`, add or update `values-pt-rBR/strings.xml` for custom surfaces, and update every required locale when compact TPMS alert vocabulary changes.

Run `DedicatedCopyContractTest` and the full app unit suite after visible-copy changes. Inspect long translations on the target landscape size.

Accessibility requirements:

- never rely on color alone;
- keep meaningful descriptions for actions and dynamic safety state;
- exclude decorative brand/vehicle imagery from focus;
- preserve at least a 48 dp dismiss target on compact alerts;
- use appropriate live-region behavior for actual safety state and non-disruptive state confirmations.

## 20. Theme and licensing boundary

The current Yamaha/Tracer identity is a personal, non-commercial fair-use customization. It does not imply sponsorship, endorsement, or affiliation with Yamaha.

- Keep the application label and operational copy generic.
- Preserve upstream Open Headunit and Mike Reid licenses, copyright notices, and attribution.
- Preserve source attribution for imported visual assets.
- Reassess the theme if the project becomes commercial, distributed as a branded product, or otherwise leaves the documented personal scope.

Do not remove the theme merely because public copy must be generic; these are separate concerns.

## 21. Verification policy

### 21.1 Application changes

At minimum run:

```sh
./gradlew :app:testGithubDebugUnitTest :app:assembleGithubDebug
```

For focused work, run the narrow tests first, then the full commands. If patches changed, repeat them from a fresh patched clone.

### 21.2 Device changes

Verify in proportion to the change:

- package/version/installed hash;
- foreground Activity and cold launch;
- Wi-Fi, Bluetooth, location, launcher, and keyboard health;
- fixed landscape and system-bar behavior;
- charging source, screen-awake behavior, brightness, unplugged timeout, and Doze;
- Android Auto connection/reconnection;
- TPMS state and overlay where relevant;
- rain lock and immediate touch interception where relevant;
- rollback command or script.

### 21.3 Minimum stability matrix

Do not declare the complete receiver stable until all applicable items have current physical evidence:

- cold start and reboot;
- automatic start without overriding active projection;
- power insertion, removal, and brief ignition interruption;
- Wi-Fi Direct association and reconnect;
- recovery after app crash/process restart;
- Bluetooth music, navigation prompts, call audio, microphone, A2DP, HFP, and AVRCP with the real intercom;
- GPS and route resume;
- day/night legibility and fixed landscape;
- prolonged charging, full brightness, navigation load, and direct-sun temperature;
- low-battery recovery;
- live TPMS sensor decoding and calibrated thresholds;
- rain touch lock during live projection;
- rollback of every disabled package and changed setting.

Known pending items must remain explicitly pending in `docs/current-state.md`. Passing unit tests or emulator checks does not close a physical-hardware item.

## 22. Documentation and evidence updates

When behavior changes:

1. Update `docs/current-state.md` for deployed facts and verification status.
2. Update the owning feature document.
3. Update `apks/README.md` when an APK, patch digest, certificate, source, or install status changes.
4. Update `README.md` only when daily operation, architecture, recovery, build, or rollback changes.
5. Update `docs/user-guide.md` when public installation, first connection, provisioning, or troubleshooting changes.
6. Capture a local snapshot after material device-state changes and publish only a minimal anonymized English summary when evidence is needed.
7. Add sanitized UI evidence after material visual changes.
8. Search for stale hashes, pending language, rejected behavior, and contradictions.
9. Verify relative links and command examples.

Write maintained documentation in English. Keep exact package names, settings keys, paths, commands, dates, and evidence levels. Do not duplicate mutable facts unnecessarily; link to the canonical source.

Never publish local raw command output or rewrite historical claims to look current. Explain only the necessary, anonymized facts in a maintained English document.

## 23. Physical safety and environmental rules

- Never configure, debug, or visually evaluate complex interactions while the vehicle is moving.
- Do not assume the phone's IP rating remains valid with USB-C exposed, connected, damaged, or under cable strain.
- Prefer POGO or properly weather-protected power when appropriate to the installation.
- Use surge protection, strain relief, anti-vibration mounting, and secondary retention.
- Check that external TPMS valve sensors clear brakes, fork, swingarm, and nearby components.
- Leak-check valves after sensor installation.
- Do not weaken Android thermal protections.
- Do not describe the device as ride-ready until the real mount, power supply, intercom, sunlight, rain, vibration, and thermal behavior have been tested.

## 24. Privacy and secrets

Never write the following into repository files, screenshots, final answers, or shared logs:

- ADB pairing codes or private keys;
- BSSID, Wi-Fi Direct SSID, passphrase, or peer address;
- Bluetooth MAC addresses;
- hardware serial numbers and other persistent device identifiers;
- account identifiers, contacts, messages, calls, notification content, or tokens;
- exact saved-network details;
- precise current location or unsanitized maps.

When command output contains a secret, summarize the relevant non-secret result instead of pasting the raw output. Redact before storing evidence.

Record repository privacy incidents only as anonymized status in `docs/current-state.md`. Never preserve removed object IDs, account handles, transport endpoints, device names, or other identifying values merely to document that they were removed.

## 25. Rollback and recovery entry points

ADB discovery:

```sh
scripts/connect-wireless.sh <receiver-ip>
```

Reversible configuration pairs:

- `scripts/configure-device-name.sh` / `scripts/rollback-device-name.sh`
- `scripts/configure-landscape.sh` / `scripts/rollback-landscape.sh`
- `scripts/configure-power-baseline.sh` / `scripts/rollback-power-baseline.sh`
- `scripts/configure-unplugged-sleep.sh` / `scripts/rollback-unplugged-sleep.sh`
- `scripts/configure-silent-notifications.sh` / `scripts/rollback-silent-notifications.sh`
- `scripts/configure-dedicated-boot.sh` / `scripts/rollback-dedicated-boot.sh`
- numbered `cleanup-batch-*.sh` / matching `rollback-cleanup-batch-*.sh`

Remove only the isolated experimental receiver package when a full application rollback is explicitly required:

```sh
adb -s <serial> uninstall com.andrerinas.headunitrevived.hfpslc
```

That command does not remove the separately installed official Open Headunit package. Uninstalling does erase the experimental package's local preferences and TPMS assignments, so prefer `install -r`, stop/start, or enabling the official rollback package when those better match the task.

## 26. Prohibited shortcuts

Do not:

- assume an ADB port, serial, model, package, hash, BSSID, or device state;
- store pairing codes or network identities for convenience;
- install an unverified APK from an unknown mirror;
- mutate the projecting phone under receiver-only authorization;
- use root-only commands or claim root is required for the validated path;
- flash, unlock, reset, or provision Device Owner without explicit authorization;
- aggressively remove system packages based only on their names;
- disable thermal controls or idle behavior to hide a bug;
- keep the screen awake unconditionally;
- fabricate TPMS or vehicle data;
- expose debug diagnostics as persistent rider-facing UI;
- restore CarPlay, Self Mode, USB, OBD, or unrelated shortcuts to the dedicated home without a new product decision;
- declare physical behavior verified from tests, logs, code review, or emulator evidence alone;
- update only one document when doing so leaves the maintained sources contradictory;
- replace reproducible patch maintenance with an undocumented dirty source tree.

## 27. Definition of done

A task is complete only when all applicable items are true:

- the request is implemented, not merely planned;
- the correct receiver identity was verified before mutation;
- pre-change state was captured when required;
- changes are scoped, reversible, and preserve unrelated user work;
- focused and full tests pass, or any gap is reported explicitly;
- changed patches apply and build from a fresh pinned clone;
- the installed APK identity and digest match the ledger;
- physical behavior is tested when the claim requires it;
- Bluetooth, Wi-Fi, power, launcher, orientation, and app foreground state are healthy;
- touch is left unlocked unless the user explicitly asks otherwise;
- secrets and personal data are absent from stored evidence;
- canonical state, feature docs, APK ledger, and evidence agree;
- pending hardware validations remain labeled pending;
- rollback is documented and practical.

End every handoff with the outcome, what was actually verified, any remaining pending physical check, and the most relevant repository file links.

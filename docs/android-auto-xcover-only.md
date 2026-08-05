---
title: Android Auto receiver research for the XCover Pro
status: verified
last_verified: 2026-08-05
scope: SM-G715U1 and an anonymized Android projecting phone
authority: technical explanation; use current-state.md for deployed state
---

# Android Auto receiver research for the XCover Pro

## Result

A software-only wireless Android Auto path was verified on the actual Samsung Galaxy XCover Pro and an Android projecting phone whose model is intentionally withheld. The working receiver is a patched build of Open Headunit 3.2.0. It does not require root, a USB dongle, or a companion application on the projecting phone.

This conclusion is specific to the versions and devices listed below. Upstream Open Headunit and Android Auto behavior can change; revalidate after upgrading either side.

Two independent defects prevented the initial connection:

1. Open Headunit opened the HFP socket but did not perform the required Hands-Free Profile Service Level Connection (SLC) exchange.
2. Automatic Wi-Fi Direct discovery returned the P2P device address instead of the group interface BSSID.

The local patch adds the missing HFP negotiation. The correct Wi-Fi Direct group-interface BSSID is stored in the receiver settings. With both changes, the phone starts native Android Auto projection over Wi-Fi Direct.

## Verified environment

### Receiver

| Field | Verified value |
| --- | --- |
| Device | Samsung Galaxy XCover Pro |
| Model | `SM-G715U1` |
| Android / One UI | Android 13 / One UI 5.1 |
| Firmware / bootloader | `G715U1UEUKEXB2` |
| Security patch | `2024-02-01` |
| Receiver base | Open Headunit 3.2.0, upstream commit `581a55f26fe74b2c93eae5778ddcd683eb08b113` |

### Projection phone

| Field | Verified value |
| --- | --- |
| Device | Android projecting phone; model withheld |
| System | Android 16 |
| Android Auto | `17.0.662234-release` |

### Successful session evidence

- The XCover created a 5 GHz Wi-Fi Direct group and became Group Owner; the local address is intentionally omitted.
- HFP SLC completed and Bluetooth message types 1, 2, and 3 completed.
- The projecting phone joined the Wi-Fi Direct group.
- `AapProjectionActivity` became the foreground activity.
- `AapService.onConnected` was observed.

The repository intentionally does not store the full BSSID, Bluetooth addresses, generated SSID, or Wi-Fi Direct passphrase.

## Root cause: incomplete HFP SLC

The upstream native flow successfully created Wi-Fi Direct, opened TCP port 5277, published the Android Auto RFCOMM UUID, and connected to the phone's HFP Audio Gateway. It then kept the socket open without initiating the HFP SLC exchange. The phone therefore did not open the Android Auto return connection.

The experimental build performs this sequence in user space:

```text
AT+BRSF=156
AT+BAC=1,2       # only when the phone advertises codec negotiation
AT+CIND=?
AT+CIND?
AT+CMER=3,0,0,1
```

HFP responses are not written to project logs because they may contain personal data. Unit tests cover feature parsing, required ordering, and optional codec negotiation.

The local base patch is [`../patches/open-headunit-hfp-slc.patch`](../patches/open-headunit-hfp-slc.patch). The TPMS and dedicated-device changes are in [`../patches/open-headunit-tpms-pairing.patch`](../patches/open-headunit-tpms-pairing.patch).

## Root cause: incorrect Wi-Fi Direct BSSID

After HFP was fixed, the first Wi-Fi association still failed. On this Samsung firmware, the fallback address was not the `link/ether` address of the active group interface, commonly named `p2p-wlan0-0`.

The working procedure was:

1. Create the native Wi-Fi Direct group.
2. Read the `link/ether` address of the active group interface.
3. Store that value as the static BSSID in Open Headunit.
4. Fully restart the receiver so it reloads the setting.
5. Retry the native connection.

The interface and address may change when the group is recreated or after a reboot. If HFP succeeds but the phone never joins Wi-Fi Direct, compare the saved BSSID with the active group interface before changing anything else.

## Reproducible build

```sh
git clone https://github.com/andreknieriem/open-headunit.git
cd open-headunit
git checkout 581a55f26fe74b2c93eae5778ddcd683eb08b113
git apply /absolute/path/to/xcover/patches/open-headunit-hfp-slc.patch
git apply /absolute/path/to/xcover/patches/open-headunit-tpms-pairing.patch
./gradlew :app:testGithubDebugUnitTest :app:assembleGithubDebug
```

The verified build used Android SDK 36 and NDK `29.0.14206865`. See [`../apks/README.md`](../apks/README.md) for the installed artifact identity and hash.

## Runtime behavior

The dedicated build:

- starts from boot and stable external power events;
- does not reopen the home screen for every `SCREEN_ON` broadcast;
- leaves USB device listening disabled by default;
- retries the native trigger on a shorter cycle than the unpatched build only while external power is present;
- cancels automatic Bluetooth wake retries as soon as external power is removed while preserving explicit manual connection;
- suppresses non-actionable native Wi-Fi Direct toasts while retaining log evidence;
- avoids replacing an active projection when Samsung emits multiple boot-complete events.

The dedicated home, power behavior, copy, and TPMS overlay are documented separately:

- [`current-state.md`](current-state.md)
- [`dedicated-home-ui.md`](dedicated-home-ui.md)
- [`tpms-integration.md`](tpms-integration.md)

## Audio boundary

Successful projection does not prove every audio topology. Music, navigation prompts, calls, and microphone behavior must be tested with the actual motorcycle intercom. Avoid ambiguous concurrent HFP connections between the projecting phone, receiver, and intercom.

## Root assessment

Root is not required for the verified projection path.

The normal Samsung/Magisk flow was not available in the inspected device state:

- `ro.boot.flash.locked=1`
- `ro.boot.vbmeta.device_state=locked`
- `ro.boot.verifiedbootstate=green`
- `ro.boot.warranty_bit=0`
- `sys.oem_unlock_allowed=0`
- OEM Unlock was absent from Developer options.

Service-tool and test-point methods may exist for this model, but they require separate explicit authorization. They can require disassembly, a paid service tool, Windows drivers, data wipes, and a permanent Knox warranty-bit change. They may also compromise the device's water sealing. These methods are outside the deployed architecture.

Root could change the XCover from the phone-side Bluetooth role to automotive HFP Client/A2DP Sink roles already present in AOSP-derived components. That might help a different audio architecture, but it would not automatically fix Android Auto receiver bugs or prove end-to-end call audio.

## USB dongle assessment

A wireless Android Auto dongle connected to the XCover as a USB host remains a fallback, not part of the current solution. On the inspected hardware, USB host mode and USB-C charging cannot be used simultaneously. The XCover Pro's POGO charging contacts could provide a separate power path, but that adds hardware and installation complexity.

## Verification still required

- Cold-start both devices repeatedly.
- Confirm whether the saved BSSID survives group recreation and reboot.
- Test music, navigation prompts, microphone, and calls with the real intercom.
- Test physical power removal, reconnection, and short ignition interruptions.
- Repeat the overnight unplugged discharge measurement with the fixed build; automatic retry cancellation is verified, but the long-duration battery improvement is not yet measured.
- Measure temperature during charging, full brightness, navigation, and direct sun.
- Revalidate the native flow after Android Auto or Open Headunit upgrades.

## External references

These sources explain upstream behavior and alternatives. They do not override the device evidence recorded in this repository.

- [Open Headunit repository and current connection guidance](https://github.com/andreknieriem/open-headunit)
- [Open Headunit issue 760: native mode regression in 3.2.0](https://github.com/andreknieriem/open-headunit/issues/760)
- [Open Headunit pull request 768: native connection fixes](https://github.com/andreknieriem/open-headunit/pull/768)
- [AOSP Android 13 automotive Bluetooth properties](https://android.googlesource.com/platform/packages/services/Car/+/refs/heads/android13-release/car_product/properties/bluetooth.prop)
- [AOSP Bluetooth HFP HF property definition](https://android.googlesource.com/platform/system/libsysprop/+/c4a3415c94366ec7ed236ab7080f43c82053425e/srcs/android/sysprop/BluetoothProperties.sysprop)
- [AOSP HFP Client service](https://android.googlesource.com/platform/packages/modules/Bluetooth/+/3980ef07d9db0ad82141025ec587c5616c86743c/android/app/src/com/android/bluetooth/hfpclient/HeadsetClientService.java)
- [Samsung Galaxy XCover Pro specifications](https://www.samsungmobilepress.com/media-assets/galaxy_xcover_pro?tab=specs)
- [Official Magisk installation guidance for Samsung devices](https://topjohnwu.github.io/Magisk/install.html)

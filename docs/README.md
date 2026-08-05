---
title: Documentation index and authority
status: current
last_verified: 2026-08-04
audience: humans and LLM agents
---

# Documentation index and authority

This directory is organized so a human or an LLM can distinguish current operating truth from historical evidence.

## Read in this order

1. [`../README.md`](../README.md) — public quick start, daily operation, recovery, build, and rollback.
2. [`user-guide.md`](user-guide.md) — complete public installation, first connection, daily operation, TPMS, provisioning, troubleshooting, and rollback.
3. [`current-state.md`](current-state.md) — canonical installed state, verification matrix, provisional values, and open risks.
4. [`android-auto-xcover-only.md`](android-auto-xcover-only.md) — Native wireless Android Auto root-cause analysis and reproducible patch build.
5. [`tpms-integration.md`](tpms-integration.md) — BLE protocol boundary, assignment flow, overlay behavior, and pending hardware validation.
6. [`dedicated-home-ui.md`](dedicated-home-ui.md) — UI hierarchy, visual validation, and personal theme boundary.
7. [`copy-guidelines.md`](copy-guidelines.md) — English-first base copy, terminology, localization, and static contracts.
8. [`initial-change-plan.md`](initial-change-plan.md) — historical plan plus execution record; not the source of current state.
9. [`release-process.md`](release-process.md) — repeatable public repository and APK release procedure.
10. [`../apks/README.md`](../apks/README.md) — APK source, version, certificate, hash, installed/rollback status.

## Authority rules

If two documents conflict:

1. prefer `current-state.md` for installed/configured facts;
2. prefer a feature document for implementation details in its scope;
3. treat `initial-change-plan.md` as historical;
4. keep raw files under `artifacts/device-snapshots/` local-only; use published English summaries as evidence.

Fix the stale lower-authority document instead of carrying the contradiction forward.

## Status vocabulary

- **Verified**: observed in a named environment — physical receiver, emulator, or automated test — with the environment stated beside the claim.
- **Configured**: set on the receiver but not necessarily exercised end to end.
- **Pending**: required validation has not been completed.
- **Provisional**: implemented value that must be calibrated or confirmed with hardware.
- **Historical**: accurate for a dated past state, not an instruction for the current system.
- **Rejected**: evaluated and intentionally excluded from the active architecture.

## Language policy

Maintained repository documentation and script output are English-first. Android base resources in `values/strings.xml` are English and act as the fallback locale. Translated resource directories remain part of the product and must not be removed merely to make the repository English-first.

Local raw snapshots may contain Android output in another language. Do not publish or translate the raw dump; interpret only the necessary facts in an anonymized English maintained document.

## Privacy policy

Never commit:

- ADB pairing codes or private keys;
- Wi-Fi Direct BSSID, SSID, password, or peer addresses;
- Bluetooth MAC addresses;
- hardware serial numbers and other persistent device identifiers;
- raw device inventories or transport endpoints;
- accounts, contacts, messages, notification contents, or application data;
- current location or unsanitized map screenshots.

## Documentation update checklist

When behavior changes:

1. update `current-state.md`;
2. update the owning feature document;
3. update APK metadata and hash when a new APK is installed;
4. capture a local dated snapshot when device state changed materially and publish only a minimal anonymized English summary;
5. update the root README only if daily operation, architecture, recovery, build, or rollback changed;
6. update `user-guide.md` when public installation, first connection, provisioning, or troubleshooting changes;
7. verify all relative links and command examples;
8. search maintained documentation and scripts for stale non-English prose.

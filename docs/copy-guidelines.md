---
title: UI copy and localization guidelines
status: current
last_verified: 2026-08-04
audience: product writers, developers, translators, and LLM agents
---

# UI copy and localization guidelines

## Goal

The public interface must work with any compatible receiver device and projecting phone. Copy describes a role, state, or action; it must not expose the personal installation's device model, vehicle, phone brand, or audio accessory.

Operational documentation may name the validated hardware when that identity is necessary to reproduce evidence. User-facing application strings may not.

## Canonical language

- English in `app/src/main/res/values/strings.xml` is the base resource and fallback locale.
- The app follows the Android system locale by default.
- Brazilian Portuguese is maintained in `values-pt-rBR/strings.xml`.
- Compact TPMS alert strings are also present in the other 18 locale directories maintained by upstream Open Headunit.
- Do not place English literals directly in Kotlin or layout files. Use Android string resources.

English-first does not mean English-only. Never remove translation directories solely to normalize repository documentation.

## Voice

- Use short, direct sentences.
- Prefer common words over implementation terminology.
- Start button labels with an action: `Connect`, `Open Android Auto`, `Resume search`.
- Describe the current state without promising a future state: `READY`, `CONNECTING`, `CONNECTED`.
- State what happened and, when useful, the next recovery action.
- Do not tell a rider how to drive inside a TPMS alert; show the safety-relevant fact.
- Avoid redundant labels such as `Alert`, `Warning`, or `Wireless` when the surrounding surface already establishes that context.
- On the dedicated home and splash, use `Android Auto`, not `Wireless Android Auto`; keep the qualifier only in technical settings where transports are compared.

## Canonical terminology

| Concept | Preferred English | Avoid |
|---|---|---|
| Projecting device | `phone`, `connected phone` | model names, `primary phone` |
| Receiver | `this device`, `receiver` | `XCover` in public UI |
| Audio source | `Played by the connected phone` | assumptions about an intercom or car stereo |
| Local audio sink | `Played by this device` | receiver model name |
| Front wheel | `Front` | vehicle-specific jargon |
| Rear wheel | `Rear` | vehicle-specific jargon |
| BLE association | `Set up sensor`, `Use sensor` | Android `pairing` when no Bluetooth bond is created |
| No live telemetry | `Waiting`, `--.-`, `-- °C` | fabricated zero values |

## Primary English states

| Context | Copy |
|---|---|
| Ready to project | `Tap to connect your phone` |
| Connecting | `Preparing the wireless connection…` |
| Projection active | `Android Auto is active` |
| Audio on phone | `Played by the connected phone` |
| Audio on receiver | `Played by this device` |
| Empty TPMS scan | `No sensor detected yet` |
| Paused TPMS scan | `Resume the search to detect nearby sensors.` |

## TPMS alert copy

The visible alert contains only:

- `FRONT` or `REAR`;
- the relevant value in PSI or °C;
- a small `TEST` badge during simulation.

Low pressure, high pressure, or high temperature remains in the accessibility description. The alert is silent, compact, dismissible, and non-modal.

## Accessibility

- Decorative vehicle/brand imagery is excluded from accessibility focus.
- Action controls retain meaningful content descriptions.
- Dynamic safety state uses an assertive live region only for actual alert content.
- Do not rely on color alone for state.
- Keep the dismiss control at least 48 dp even when the visible alert is compact.

## Enforcement

`DedicatedCopyContractTest` checks that:

- owner-specific labels stay out of public string resources and the app label remains generic;
- connection and audio states remain role-based;
- customized messages use localized resources;
- keymap, disclaimer, and About surfaces do not regress to hard-coded English.

When adding visible copy:

1. add the English base resource;
2. add or update `pt-BR` when the custom surface supports it;
3. update every required TPMS alert locale when the compact alert vocabulary changes;
4. run `:app:testGithubDebugUnitTest` and `:app:assembleGithubDebug`;
5. inspect long text on the target landscape dimensions.

## Theme boundary

Operational copy and the application label are generic. The Yamaha identity forms the current personal, non-commercial fair-use theme and does not imply sponsorship, endorsement, or affiliation. Preserve the Open Headunit and Mike Reid license and attribution files.

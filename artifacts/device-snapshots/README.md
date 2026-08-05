---
title: Local device snapshot policy
status: maintained
last_updated: 2026-08-04
---

# Local device snapshot policy

Raw device inventories belong on the operator's local machine. They are useful for comparison, troubleshooting, and rollback, but can contain transport endpoints, firmware fingerprints, timestamps, battery history, and device-specific diagnostics.

## Rules

- Keep `*.txt` snapshots local; `.gitignore` excludes them from the public repository.
- Do not publish a raw snapshot, even when its collection command is designed to omit application data.
- A local snapshot describes only its capture time; it is not the current source of truth.
- Use [`../../docs/current-state.md`](../../docs/current-state.md) for the deployed configuration.
- Snapshot scripts and headings must use English.
- Do not collect pairing codes, passwords, private keys, contacts, notification contents, precise location history, or application-private data.
- Publish only an English summary containing the minimum facts needed to support a claim, with transport addresses, ports, hardware serials, peer identities, and unique device details removed.
- When local evidence conflicts with maintained documentation, update the maintained interpretation with the date and reason without uploading the raw dump.

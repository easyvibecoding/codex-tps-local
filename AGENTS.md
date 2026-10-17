# Codex TPS Local

This macOS-only fork must remain local-only. User instructions take priority.

- Preserve token accounting, fork/replay handling, and cross-file deduplication.
- Never add network transports, update downloads, pairing, credentials, host telemetry, or conversation rendering.
- Keep packaged executables sandboxed without network entitlements. The only extra filesystem grant is read-only `~/.codex/sessions/`.
- A new runtime file or entitlement requires explicit security review and an update to the capability check. Static checks supplement, not replace, runtime verification.
- Preserve copyright/license notices and upstream attribution.
- Keep README.md and README.zh-TW.md aligned. Architecture, operations, and development docs own their corresponding contracts.
- Run `python3 scripts/verify-local-only.py`, `swift test`, and `scripts/build-app.sh` as applicable. If XCTest is unavailable, use macOS CI with full Xcode and record that local tests were unavailable.
- Installation claims require installed signature/entitlement readback, real local metrics, GUI refresh, and a check for process-owned IP sockets. Never label ad-hoc local builds as notarized.
- Keep user data, local metrics, absolute user paths, credentials, and machine-specific receipts out of commits.
- GitHub commit subjects, issue/PR titles, and descriptions should be in English.

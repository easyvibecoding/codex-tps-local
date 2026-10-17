# Architecture and privacy

The core module exposes `SessionScanner.refresh()` and `UsageSnapshot`. It owns incremental reads, structural event parsing, fork/replay handling, deduplication, and window accounting. The SwiftUI app and snapshot command use that same interface.

Only `event_msg` / `token_count` events contribute usage. `last_token_usage` supplies request increments; cumulative usage helps detect replay/duplicates. Cached input and reasoning output are subsets. Accounting code and its regression tests are retained from upstream.

The app owns refresh scheduling, window selection, optional login startup, and local preferences. It has no network or Keychain module. The supported source tree contains no Gateway/provider/plugin or Windows implementation.

## Packaged policy

`Resources/LocalOnly.entitlements` enables App Sandbox and grants read-only `/.codex/sessions/` relative to the real user's home. No network client/server, Keychain group, automation, or general file access entitlement is present. The real home is resolved using the OS account record because Foundation redirects the home directory to the sandbox container.

The GUI intentionally ignores `CODEX_HOME`: the static signed policy supports only the default session root. The source-built snapshot can use `CODEX_HOME` for development fixtures; the packaged snapshot is constrained by its signed entitlements and cannot expand its access using this variable.

App Sandbox still permits normal system/framework access and app-container storage. This is not a claim that the process can access absolutely no other file, nor protection against an already-compromised OS. Session JSONL bytes necessarily pass through the scanner, but only accounting/structural fields are decoded and no raw log output is produced.

The capability check uses an exact runtime-file and entitlement allowlist plus prohibited API checks. It detects accidental reintroduction, not arbitrary malicious code. Actual packaged signatures, runtime metrics, and socket observations remain required.

Original implementation: [OPL Fleet Agent](https://github.com/gaofeng21cn/opl-fleet-agent), commit `8ea30539cf7232bc609bc6308e5020c1c9213970`. Git history retains the original network implementation; do not install historical upstream releases as a local-only build.

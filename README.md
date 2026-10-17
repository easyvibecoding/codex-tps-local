# Codex TPS Local

A macOS menu-bar monitor for local Codex token usage. This fork removes the OPL Fleet transport, discovery, pairing, credentials, host telemetry, pet sharing, and automatic updater code. It is not compatible with OPL Fleet gateways.

Forked from [gaofeng21cn/opl-fleet-agent](https://github.com/gaofeng21cn/opl-fleet-agent) at `8ea30539cf7232bc609bc6308e5020c1c9213970` (runtime source identical to v0.2.46). Original copyright and Apache-2.0 notices are retained. This community project is not affiliated with OpenAI.

[繁體中文](README.zh-TW.md)

## Privacy

- No HTTP server, Bonjour advertisement, network discovery, outgoing telemetry, remote pairing, credential storage, host sampling, or update requests.
- Packaged app and snapshot executable use App Sandbox, with **no network client/server entitlements**. The only extra filesystem grant is read-only access to `~/.codex/sessions/`.
- Independent app identity: `io.github.easyvibecoding.codex-tps-local`. Upstream settings and Keychain entries are not imported.
- Session files are read in chunks. Only structural accounting fields are decoded; conversation bodies are not rendered, persisted, or transmitted.
- Settings remain in the app's own container. Login startup is optional and off on a new installation.

See [architecture](docs/architecture.md) for limitations and [operations](docs/operations.md) for installation acceptance.

## Install locally

Requires macOS 13+, Swift 6 and Apple's Command Line Tools. Full Xcode is required for the inherited XCTest suite. There are no third-party runtime packages.

```sh
git clone https://github.com/easyvibecoding/codex-tps-local.git
cd codex-tps-local
./scripts/install.sh
```

The script builds from local source, ad-hoc signs with the sandbox policy, stages and verifies the app, and installs `/Applications/Codex TPS Local.app`. An existing copy at that exact path is backed up during replacement and restored if verification fails. It never downloads or installs upstream releases.

This is a **local development build**, not a Developer ID signed or Apple-notarized release. Do not disable Gatekeeper. There is no automatic update path; future updates require reviewing and rebuilding this fork.

Use `--no-launch` to install without opening, or `CODEX_TPS_LOCAL_INSTALL_DIR` to select a different Applications directory. The sandboxed GUI reads the default Codex sessions directory. Custom Codex homes are not supported by the packaged GUI.

## Metrics

The 1m, 5m, 30m, and 1h views divide completed-request token totals by the entire window duration. Input includes cached input; output includes reasoning output. Subsets are displayed but not double-counted. This is aggregate throughput, **not streaming output speed or billing evidence**.

The bundled read-only snapshot command is:

```sh
'/Applications/Codex TPS Local.app/Contents/MacOS/codex-tps-local-snapshot' --json
```

## Development

See [development](docs/development.md). The Windows app, provider/plugin, headless Gateway agent, and upstream release machinery have been removed from this macOS-only fork. Git history still contains upstream code; only the current local-only tree is supported.

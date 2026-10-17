# Development

Use macOS 13+ and Swift 6. Full Xcode supplies XCTest; Command Line Tools can build the app and snapshot but may not run XCTest.

```sh
python3 scripts/verify-local-only.py
xcrun swift-format lint --recursive Sources Tests Package.swift
zsh -n scripts/build-app.sh scripts/install.sh
swift test
./scripts/build-app.sh
python3 scripts/verify-local-only.py 'dist/Codex TPS Local.app'
git diff --check
```

CI runs the retained parser/scanner/metrics tests on a macOS runner with Xcode, then builds and verifies both signed executables. No remote releases or deployment credentials are configured.

`build-app.sh` builds for the current host architecture and signs ad-hoc with hardened runtime and the reviewed sandbox policy. Its output is not a notarized public release. Source/debug executables created by `swift run` do not establish the packaged sandbox policy.

Use `--preview-window` when launching the GUI to inspect the same panel in a regular window. No preview-specific network or telemetry path exists. Installation acceptance is described in [operations](operations.md).

# Local installation and acceptance

Build/install with `scripts/install.sh`. It only replaces the exact `Codex TPS Local.app` destination and never terminates the upstream app. `--no-launch` leaves it stopped; `CODEX_TPS_LOCAL_INSTALL_DIR` changes the install directory.

Read back the installed bundle identity/version, strict code signature, and exact sandbox entitlements using `scripts/verify-local-only.py '/Applications/Codex TPS Local.app'`. Both the GUI and bundled snapshot must carry the same restricted policy. The app is locally ad-hoc signed, not notarized.

Run the installed `Contents/MacOS/codex-tps-local-snapshot --json`. Confirm the default session root exists and `status` is `ready`; zero completed requests can be valid. Then open the GUI, refresh its panel, and observe current metrics. Check the GUI process with `lsof -nP -a -p PID -i` after launch and a refresh cycle: there should be no process-owned TCP/UDP sockets.

If the sessions directory is missing or inaccessible, the app must show an unavailable/error state. Do not broaden filesystem entitlements or disable the sandbox to force a successful read. Other Codex homes require a separately reviewed design change.

There are no remote pairing steps, tokens, update servers, or external services to configure. Login startup is off on a new installation. Quit the app and remove the exact installed app bundle to uninstall. Preferences are in its independent macOS sandbox container; do not delete upstream data or the Codex sessions directory.

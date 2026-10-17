#!/usr/bin/env python3
"""Fail closed on new capabilities or unreviewed runtime files."""
from pathlib import Path
import plistlib
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
EXPECTED = {
    "com.apple.security.app-sandbox": True,
    "com.apple.security.temporary-exception.files.home-relative-path.read-only": ["/.codex/sessions/"],
}
RUNTIME_FILES = {
    "CodexTPSCore/CodexLogModels.swift", "CodexTPSCore/SessionScanner.swift",
    "CodexTPSCore/TokenEventParser.swift", "CodexTPSCore/UsageMetrics.swift",
    "CodexTPSLocal/CodexTPSLocalApp.swift", "CodexTPSLocal/CodexTPSLocalAppDelegate.swift",
    "CodexTPSLocal/MonitorPanel.swift", "CodexTPSLocal/MonitorStore.swift",
    "CodexTPSSnapshot/main.swift",
}


def check(condition, message):
    if not condition:
        raise SystemExit(message)


def main():
    check(plistlib.loads((ROOT / "Resources/LocalOnly.entitlements").read_bytes()) == EXPECTED,
          "Sandbox capabilities changed; explicit security review required")
    files = {str(p.relative_to(ROOT / "Sources")) for p in (ROOT / "Sources").rglob("*") if p.is_file()}
    check(files == RUNTIME_FILES, "Runtime file set changed; explicit security review required")
    prohibited = re.compile(r"\b(URLSession|URLRequest|NWListener|NWConnection|NetService|SecItem\w*|Process|dlopen|popen|socket|connect|bind|listen)\b|(?<![\w.])system\s*\(|https?://|import\s+(Network|Security|WebKit)")
    for relative in sorted(files):
        check(not prohibited.search((ROOT / "Sources" / relative).read_text()),
              "Unexpected networking, credentials, or process execution in " + relative)
    if len(sys.argv) > 1:
        app = Path(sys.argv[1]).resolve()
        info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
        check(info["CFBundleIdentifier"] == "io.github.easyvibecoding.codex-tps-local", "Wrong app identity")
        check(not {"NSBonjourServices", "NSLocalNetworkUsageDescription"} & info.keys(), "LAN metadata remains")
        actual = {str(p.relative_to(app / "Contents/MacOS")) for p in (app / "Contents/MacOS").rglob("*") if p.is_file()}
        check(actual == {"CodexTPSLocal"}, "Unexpected bundled executable")
        snapshot = app / "Contents/Helpers/Codex TPS Snapshot.app"
        helper_files = {str(p.relative_to(app / "Contents/Helpers")) for p in (app / "Contents/Helpers").rglob("*") if p.is_file()}
        check(helper_files == {
            "Codex TPS Snapshot.app/Contents/Info.plist",
            "Codex TPS Snapshot.app/Contents/MacOS/codex-tps-local-snapshot",
            "Codex TPS Snapshot.app/Contents/_CodeSignature/CodeResources",
        }, "Unexpected helper bundle contents")
        snapshot_info = plistlib.loads((snapshot / "Contents/Info.plist").read_bytes())
        check(snapshot_info["CFBundleIdentifier"] == info["CFBundleIdentifier"] + ".snapshot", "Wrong snapshot identity")
        check(not list(app.rglob("*.sh")), "Bundled installer or updater remains")
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
        for binary in [app, snapshot]:
            result = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(binary)],
                                    capture_output=True, check=True)
            check(plistlib.loads(result.stdout) == EXPECTED, "Signed entitlements differ from the reviewed policy")
    print("Local-only source and requested bundle checks passed")


if __name__ == "__main__":
    main()

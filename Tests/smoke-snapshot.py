#!/usr/bin/env python3
"""Exercise the actual sandboxed helper; fixture creation is CI-only and fail-closed."""
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import sys

app = Path(sys.argv[1]).resolve()
helper = app / "Contents/Helpers/Codex TPS Snapshot.app/Contents/MacOS/codex-tps-local-snapshot"
fixture = None
sessions = Path.home() / ".codex/sessions"
if "--ci-fixture" in sys.argv:
    if os.environ.get("GITHUB_ACTIONS") != "true" or sessions.exists():
        raise SystemExit("CI fixture requires a fresh GitHub runner without a sessions directory")
    sessions.mkdir(parents=True)
    fixture = sessions / "local-only-fixture.jsonl"
    usage = {"input_tokens": 100, "output_tokens": 20, "total_tokens": 120}
    fixture.write_text(json.dumps({
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "type": "event_msg",
        "payload": {"type": "token_count", "info": {
            "last_token_usage": usage, "total_token_usage": usage,
        }},
    }, separators=(",", ":")) + "\n")
try:
    result = subprocess.run([str(helper), "--json"], capture_output=True, text=True,
                            check=True, timeout=60)
    snapshot = json.loads(result.stdout)
    assert snapshot["status"] == "ready", snapshot["status"]
    assert snapshot["malformedRelevantLines"] == 0
    if fixture:
        assert snapshot["oneMinute"]["totalTokens"] == 120
        assert snapshot["oneMinute"]["requestCount"] == 1
    print("Packaged sandboxed snapshot: ready, zero malformed accounting events")
finally:
    if fixture:
        fixture.unlink()
        sessions.rmdir()

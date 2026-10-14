"""Regression tests for public R2 custom-domain exposure guards."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("provision-r2-storage.sh")

MOCK_CURL = r'''#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

args = sys.argv[1:]

def value_after(flag):
    try:
        return args[args.index(flag) + 1]
    except (ValueError, IndexError):
        return None

method = value_after("--request") or "GET"
output = value_after("--output")
url = args[-1]
log = os.environ.get("MOCK_CURL_CALL_LOG")
if log:
    with open(log, "a", encoding="utf-8") as stream:
        stream.write(f"{method} {url}\n")

if url.endswith("/r2/buckets/maps-prod"):
    status = "200"
    payload = {"success": True, "result": {"name": "maps-prod"}}
elif url.endswith("/r2/buckets/maps-prod/domains/custom"):
    status = "200"
    payload = {"success": True, "result": {"domains": []}}
else:
    status = "500"
    payload = {"success": False, "errors": [{"message": "Unexpected mocked API request"}]}

if output:
    Path(output).write_text(json.dumps(payload), encoding="utf-8")
print(status, end="")
'''


class R2ProvisioningSafetyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        fake_curl = bin_dir / "curl"
        fake_curl.write_text(MOCK_CURL, encoding="utf-8")
        fake_curl.chmod(0o755)
        self.call_log = self.root / "curl-calls.log"
        self.env = os.environ.copy()
        self.env.update(
            {
                "PATH": f"{bin_dir}{os.pathsep}{self.env['PATH']}",
                "CLOUDFLARE_API_TOKEN": "test-token",
                "R2_ACCOUNT_ID": "a" * 32,
                "CLOUDFLARE_ZONE_ID": "b" * 32,
                "R2_BUCKET": "maps-prod",
                "MAPS_PUBLIC_BASE_URL": "https://maps.example.invalid",
                "MOCK_CURL_CALL_LOG": str(self.call_log),
            }
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_existing_unconfigured_bucket_is_not_exposed(self) -> None:
        result = subprocess.run(
            ["bash", str(SCRIPT)],
            env=self.env,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Refusing to expose an uninspected bucket", result.stderr)
        calls = self.call_log.read_text(encoding="utf-8").splitlines()
        self.assertFalse(
            any(line.startswith("POST https://api.cloudflare.com/client/v4/accounts/")
                and line.endswith("/domains/custom") for line in calls),
            "must not attach a public custom domain to an existing uninspected bucket",
        )


if __name__ == "__main__":
    unittest.main()

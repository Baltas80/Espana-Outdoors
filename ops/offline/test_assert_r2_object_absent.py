"""Tests for the immutable R2 object absence guard."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("assert-r2-object-absent.sh")

MOCK_AWS = r'''#!/usr/bin/env python3
import os
import sys

args = sys.argv[1:]
mode = os.environ.get("MOCK_AWS_MODE", "missing")

if "head-bucket" in args:
    if mode in ("no_such_bucket", "network"):
        message = (
            "An error occurred (404): NoSuchBucket"
            if mode == "no_such_bucket"
            else "Could not connect to the endpoint URL"
        )
        print(message, file=sys.stderr)
        raise SystemExit(255)
    raise SystemExit(0)

if mode == "exists":
    raise SystemExit(0)
if mode == "missing":
    print("An error occurred (404) when calling the HeadObject operation: Not Found", file=sys.stderr)
elif mode == "denied":
    print("An error occurred (403) when calling the HeadObject operation: AccessDenied", file=sys.stderr)
elif mode == "object_network":
    print("Could not connect to the endpoint URL", file=sys.stderr)
else:
    print("unexpected HeadObject failure", file=sys.stderr)
raise SystemExit(255)
'''


class ImmutableR2GuardTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.bin_dir = Path(self.temp.name) / "bin"
        self.bin_dir.mkdir()
        mock = self.bin_dir / "aws"
        mock.write_text(MOCK_AWS, encoding="utf-8")
        mock.chmod(0o755)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_guard(self, mode: str) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env.update(
            {
                "PATH": f"{self.bin_dir}{os.pathsep}{env['PATH']}",
                "MOCK_AWS_MODE": mode,
            }
        )
        return subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "maps-prod",
                "basemap/spain/2026-10-14/spain.pmtiles",
                "https://r2.example.invalid",
            ],
            env=env,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )

    def test_confirmed_missing_object_allows_publication(self) -> None:
        result = self.run_guard("missing")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("key is absent", result.stdout)

    def test_existing_object_blocks_overwrite(self) -> None:
        result = self.run_guard("exists")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refusing to overwrite", result.stderr)

    def test_access_denied_fails_closed(self) -> None:
        result = self.run_guard("denied")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not prove", result.stderr)

    def test_missing_bucket_fails_closed(self) -> None:
        result = self.run_guard("no_such_bucket")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not verify the R2 bucket", result.stderr)

    def test_bucket_network_failure_fails_closed(self) -> None:
        result = self.run_guard("network")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not verify the R2 bucket", result.stderr)

    def test_object_network_failure_fails_closed(self) -> None:
        result = self.run_guard("object_network")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not prove", result.stderr)

    def test_unknown_head_failure_fails_closed(self) -> None:
        result = self.run_guard("unknown")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unrecognized HeadObject failure", result.stderr)


if __name__ == "__main__":
    unittest.main()

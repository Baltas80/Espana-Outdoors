"""Contract tests for the bounded PMTiles HTTP Range release gate."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("verify-pmtiles-http.sh")

MOCK_CURL = r'''#!/usr/bin/env python3
import os
import sys
from pathlib import Path

args = sys.argv[1:]

def value_after(flag):
    try:
        return args[args.index(flag) + 1]
    except (ValueError, IndexError):
        return None

header_path = value_after("--dump-header")
is_head = "--head" in args
mode = os.environ.get("MOCK_CURL_MODE", "valid")

if is_head:
    Path(header_path).write_bytes(
        b"HTTP/1.1 200 OK\r\nContent-Length: 4096\r\nAccept-Ranges: bytes\r\n\r\n"
    )
    print("200", end="")
    raise SystemExit(0)

if mode == "ignore_range":
    Path(header_path).write_bytes(
        b"HTTP/1.1 200 OK\r\nContent-Length: 1000000\r\n\r\n"
    )
    # A correct script closes the stdout pipe after 2 KiB instead of writing
    # this full response to a file or downloading the object indefinitely.
    sys.stdout.buffer.write(b"x" * 1_000_000)
    raise SystemExit(0)

content_range = "bytes 0-1023/4096"
body = b"x" * 1024
if mode == "wrong_start":
    content_range = "bytes 1-1024/4096"
elif mode == "wrong_total":
    content_range = "bytes 0-1023/4097"
elif mode == "short_body":
    body = b"x" * 1023

headers = (
    "HTTP/1.1 206 Partial Content\r\n"
    f"Content-Range: {content_range}\r\n"
    f"Content-Length: {len(body)}\r\n"
    "\r\n"
).encode("ascii")
Path(header_path).write_bytes(headers)
sys.stdout.buffer.write(body)
'''


class PmtilesHttpGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.bin_dir = Path(self.temp.name) / "bin"
        self.bin_dir.mkdir()
        fake_curl = self.bin_dir / "curl"
        fake_curl.write_text(MOCK_CURL, encoding="utf-8")
        fake_curl.chmod(0o755)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_gate(self, mode: str = "valid") -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env.update(
            {
                "PATH": f"{self.bin_dir}{os.pathsep}{env['PATH']}",
                "MAP_PMTILES_URL": "https://maps.example.invalid/spain.pmtiles",
                "MOCK_CURL_MODE": mode,
            }
        )
        return subprocess.run(
            ["bash", str(SCRIPT)],
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )

    def test_accepts_valid_range_and_exact_body(self) -> None:
        result = self.run_gate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Range verified: HTTP 206, bytes 0-1023/4096, body=1024 bytes", result.stdout)
        self.assertIn("PMTiles HTTP range gate: PASS", result.stdout)

    def test_rejects_server_that_ignores_range_without_downloading_object(self) -> None:
        result = self.run_gate("ignore_range")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refusing an unbounded map download", result.stderr)

    def test_rejects_nonzero_range_start(self) -> None:
        result = self.run_gate("wrong_start")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("inconsistent Content-Range", result.stderr)

    def test_rejects_inconsistent_total_size(self) -> None:
        result = self.run_gate("wrong_total")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("inconsistent Content-Range", result.stderr)

    def test_rejects_short_range_body(self) -> None:
        result = self.run_gate("short_body")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("range body is 1023 bytes", result.stderr)


if __name__ == "__main__":
    unittest.main()

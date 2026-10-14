"""Tests for full public PMTiles integrity verification."""
import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("verify-public-pmtiles-sha256.sh")


class PublicPmtilesSha256Tests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.catalog = self.root / "catalog.json"
        self.map_file = self.root / "map.pmtiles"
        self.map_file.write_bytes(b"tiny test PMTiles payload")
        self.fake_curl = self.bin / "curl"
        fake = """#!/usr/bin/env python3
import shutil, sys
args = sys.argv[1:]
out = args[args.index('--output') + 1]
url = args[-1]
if url == 'https://example.test/catalog.json':
    shutil.copyfile(%r, out)
elif url == 'https://example.test/map.pmtiles':
    shutil.copyfile(%r, out)
else:
    sys.exit('unexpected URL: ' + url)
""" % (str(self.catalog), str(self.map_file))
        self.fake_curl.write_text(fake, encoding="utf-8")
        self.fake_curl.chmod(0o755)
        self.env = os.environ.copy()
        self.env["PATH"] = str(self.bin) + os.pathsep + self.env["PATH"]
        self.env["MAP_SHA"] = hashlib.sha256(self.map_file.read_bytes()).hexdigest()

    def tearDown(self):
        self.tmp.cleanup()

    def write_catalog(self, sha=None, size=None):
        payload = [{
            "id": "spain",
            "downloadUrl": "https://example.test/map.pmtiles",
            "sizeBytes": size if size is not None else self.map_file.stat().st_size,
            "sha256": sha if sha is not None else self.env["MAP_SHA"],
        }]
        self.catalog.write_text(json.dumps(payload), encoding="utf-8")

    def run_script(self):
        return subprocess.run(
            ["bash", str(SCRIPT), "https://example.test/catalog.json"],
            env=self.env, text=True, capture_output=True, timeout=10,
        )

    def test_passes_when_public_bytes_match_catalog(self):
        self.write_catalog()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("public_pmtiles_integrity=PASS", result.stdout)

    def test_fails_when_sha256_does_not_match(self):
        self.write_catalog(sha="0" * 64)
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SHA-256 mismatch", result.stderr)

    def test_fails_when_size_does_not_match(self):
        self.write_catalog(size=self.map_file.stat().st_size + 1)
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("size mismatch", result.stderr)

    def test_rejects_non_https_map_url(self):
        self.write_catalog()
        payload = json.loads(self.catalog.read_text())
        payload[0]["downloadUrl"] = "http://example.test/map.pmtiles"
        self.catalog.write_text(json.dumps(payload), encoding="utf-8")
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("HTTPS", result.stderr)


if __name__ == "__main__":
    unittest.main()

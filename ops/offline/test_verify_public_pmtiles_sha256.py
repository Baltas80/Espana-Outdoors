"""Tests for full public PMTiles integrity verification."""
import hashlib, json, os, subprocess, tempfile, unittest
from pathlib import Path
SCRIPT = Path(__file__).with_name("verify-public-pmtiles-sha256.sh")
class PublicPmtilesSha256Tests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"; self.bin.mkdir()
        self.catalog = self.root / "catalog.json"; self.map_file = self.root / "map.pmtiles"
        self.map_file.write_bytes(b"tiny test PMTiles payload")
        fake = """#!/usr/bin/env python3
import shutil, sys
a=sys.argv[1:]; out=a[a.index('--output')+1]; url=a[-1]
if url == 'https://example.test/catalog.json': shutil.copyfile(%r,out)
elif url == 'https://example.test/map.pmtiles': shutil.copyfile(%r,out)
else: sys.exit('unexpected URL: '+url)
""" % (str(self.catalog), str(self.map_file))
        curl=self.bin/"curl"; curl.write_text(fake,encoding="utf-8"); curl.chmod(0o755)
        self.env=os.environ.copy(); self.env["PATH"]=str(self.bin)+os.pathsep+self.env["PATH"]
        self.sha=hashlib.sha256(self.map_file.read_bytes()).hexdigest()
    def tearDown(self): self.tmp.cleanup()
    def write_catalog(self, sha=None, size=None):
        self.catalog.write_text(json.dumps([{"id":"spain","downloadUrl":"https://example.test/map.pmtiles","sizeBytes":size if size is not None else self.map_file.stat().st_size,"sha256":sha if sha is not None else self.sha}]),encoding="utf-8")
    def run_script(self):
        return subprocess.run(["bash",str(SCRIPT),"https://example.test/catalog.json"],env=self.env,text=True,capture_output=True,timeout=10)
    def test_passes_when_public_bytes_match_catalog(self):
        self.write_catalog(); r=self.run_script(); self.assertEqual(r.returncode,0,r.stderr); self.assertIn("public_pmtiles_integrity=PASS",r.stdout)
    def test_fails_when_sha256_does_not_match(self):
        self.write_catalog(sha="0"*64); r=self.run_script(); self.assertNotEqual(r.returncode,0); self.assertIn("SHA-256 mismatch",r.stderr)
    def test_fails_when_size_does_not_match(self):
        self.write_catalog(size=self.map_file.stat().st_size+1); r=self.run_script(); self.assertNotEqual(r.returncode,0); self.assertIn("size mismatch",r.stderr)
    def test_rejects_non_https_map_url(self):
        self.write_catalog(); data=json.loads(self.catalog.read_text()); data[0]["downloadUrl"]="http://example.test/map.pmtiles"; self.catalog.write_text(json.dumps(data))
        r=self.run_script(); self.assertNotEqual(r.returncode,0); self.assertIn("HTTPS",r.stderr)
if __name__ == "__main__": unittest.main()

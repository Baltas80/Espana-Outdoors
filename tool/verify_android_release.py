#!/usr/bin/env python3
"""Verify the Android release archive contains the required app assets.

PMTiles is fetched through the approved HTTPS catalog at runtime and is not
bundled as a native MWM/CoMaps asset.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from zipfile import BadZipFile, ZipFile

REQUIRED_SUFFIXES = (
    "assets/flutter_assets/assets/brand/espana_outdoor_mark.svg",
    "assets/flutter_assets/assets/landscapes/picos_europa_land01.svg",
    "assets/flutter_assets/assets/backgrounds/bg_map.svg",
    "assets/flutter_assets/assets/visuals/hero_map.svg",
)

FORBIDDEN_SUFFIXES = (
    "assets/flutter_assets/assets/maps/World.mwm",
    "assets/flutter_assets/assets/maps/WorldCoasts.mwm",
    "assets/flutter_assets/assets/maps/icudt75l.dat",
    "assets/flutter_assets/assets/comaps_data/countries.txt",
)

def _has_suffix(names: set[str], suffix: str) -> bool:
    return any(name == suffix or name.endswith("/" + suffix) for name in names)

def verify(path: Path) -> list[str]:
    try:
        with ZipFile(path) as archive:
            names = set(archive.namelist())
    except (BadZipFile, OSError) as exc:
        raise SystemExit(f"Invalid Android release archive: {path}: {exc}") from exc

    missing = [suffix for suffix in REQUIRED_SUFFIXES if not _has_suffix(names, suffix)]
    legacy = [suffix for suffix in FORBIDDEN_SUFFIXES if _has_suffix(names, suffix)]

    if missing:
        raise SystemExit("Android release asset verification failed; missing: " + ", ".join(missing))
    if legacy:
        raise SystemExit("Android release contains forbidden legacy map assets: " + ", ".join(legacy))
    if not _has_suffix(names, "AndroidManifest.xml"):
        raise SystemExit("Android release asset verification failed; AndroidManifest.xml is missing.")

    return sorted(suffix for suffix in REQUIRED_SUFFIXES if _has_suffix(names, suffix))

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--aab", type=Path)
    args = parser.parse_args()
    archives = [p for p in (args.apk, args.aab) if p is not None]
    if not archives:
        parser.error("Provide --apk and/or --aab.")
    for archive in archives:
        verified = verify(archive)
        print(f"verified={archive}")
        for item in verified:
            print(f"asset={item}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

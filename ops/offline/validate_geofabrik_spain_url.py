#!/usr/bin/env python3
"""Validate immutable, date-stamped Geofabrik Spain OSM PBF URLs."""

from __future__ import annotations

import re
import sys
from datetime import date
from urllib.parse import urlsplit

EXPECTED_HOST = "download.geofabrik.de"
EXPECTED_PATH = re.compile(r"^/europe/spain-(\d{6})\.osm\.pbf$")


def validation_error(raw_url: str) -> str | None:
    """Return an explanatory error when URL is not a dated Spain snapshot."""
    try:
        parsed = urlsplit(raw_url)
        port = parsed.port
    except ValueError:
        return "OSM_URL is not a valid URL."

    if parsed.scheme != "https":
        return "OSM_URL must use HTTPS."
    if (
        parsed.hostname != EXPECTED_HOST
        or parsed.username is not None
        or parsed.password is not None
        or port not in (None, 443)
    ):
        return f"OSM_URL must use the official host {EXPECTED_HOST}."
    if parsed.query or parsed.fragment:
        return "OSM_URL must not contain a query string or fragment."

    match = EXPECTED_PATH.fullmatch(parsed.path)
    if not match:
        return (
            "OSM_URL must point to a dated Spain snapshot, "
            "for example https://download.geofabrik.de/europe/"
            "spain-261012.osm.pbf; mutable '*-latest.osm.pbf' URLs are rejected."
        )

    stamp = match.group(1)
    year = 2000 + int(stamp[0:2])
    month = int(stamp[2:4])
    day = int(stamp[4:6])
    try:
        date(year, month, day)
    except ValueError:
        return "OSM_URL contains an invalid YYMMDD snapshot date."
    return None


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"Usage: {argv[0]} OSM_URL", file=sys.stderr)
        return 2
    error = validation_error(argv[1])
    if error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("geofabrik_spain_snapshot=verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

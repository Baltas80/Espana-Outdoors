"""Offline map catalog contract validation.

The parser is separated from network I/O so the release contract can be tested
without relying on live production endpoints.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


class HTTPSOnlyRedirectHandler(urllib.request.HTTPRedirectHandler):
    """Reject any redirect that leaves HTTPS, including temporary downgrade hops."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        target = urllib.parse.urlparse(newurl)
        if (
            target.scheme != "https"
            or not target.hostname
            or target.username is not None
            or target.password is not None
        ):
            raise ValueError(
                "PMTiles redirect must remain HTTPS and must not include embedded credentials."
            )
        return super().redirect_request(req, fp, code, msg, headers, newurl)


REQUIRED_SPAIN_FIELDS = (
    "name",
    "description",
    "providerId",
    "licenseUrl",
    "attribution",
    "downloadUrl",
    "sizeBytes",
    "updatedAt",
    "sha256",
)


def validate_catalog_payload(
    payload: Any,
    configured_pmtiles_url: str = "",
) -> dict[str, Any]:
    if not isinstance(payload, list):
        raise ValueError("Offline catalog must be a JSON array.")

    spain = next(
        (
            item
            for item in payload
            if isinstance(item, dict) and item.get("id") == "spain"
        ),
        None,
    )
    if spain is None:
        raise ValueError("Offline catalog does not contain the spain entry.")

    for key in REQUIRED_SPAIN_FIELDS:
        if key not in spain:
            raise ValueError(f"Catalog spain entry is missing {key}.")

    if spain["providerId"] != "approved-pmtiles-catalog":
        raise ValueError("Catalog spain providerId is not approved-pmtiles-catalog.")

    for key in ("licenseUrl", "downloadUrl"):
        value = spain[key]
        parsed = urllib.parse.urlparse(value if isinstance(value, str) else "")
        if (
            parsed.scheme != "https"
            or not parsed.hostname
            or parsed.username is not None
            or parsed.password is not None
        ):
            raise ValueError(f"{key} must be a complete HTTPS URL without embedded credentials.")

    if configured_pmtiles_url:
        configured = urllib.parse.urlparse(configured_pmtiles_url)
        if (
            configured.scheme != "https"
            or not configured.hostname
            or configured.username is not None
            or configured.password is not None
        ):
            raise ValueError("MAP_PMTILES_URL must be a complete HTTPS URL without embedded credentials.")
        if configured_pmtiles_url != spain["downloadUrl"]:
            raise ValueError(
                "Configured MAP_PMTILES_URL does not match the Spain catalog downloadUrl."
            )

    sha = str(spain["sha256"]).lower()
    if len(sha) != 64 or any(character not in "0123456789abcdef" for character in sha):
        raise ValueError("Catalog spain sha256 is not a valid SHA-256 hex digest.")

    size = spain["sizeBytes"]
    if type(size) is not int or size <= 0:
        raise ValueError("Catalog spain sizeBytes must be a positive integer.")

    for key in ("name", "description", "attribution"):
        if not isinstance(spain[key], str) or not spain[key].strip():
            raise ValueError(f"Catalog spain {key} must not be empty.")

    updated_at = spain["updatedAt"]
    if not isinstance(updated_at, str) or not updated_at.strip():
        raise ValueError("Catalog spain updatedAt must not be empty.")
    try:
        parsed_updated_at = datetime.datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError("Catalog spain updatedAt must be an ISO-8601 timestamp.") from exc
    if parsed_updated_at.tzinfo is None:
        raise ValueError("Catalog spain updatedAt must include a timezone.")

    return spain


def validate_catalog_file(
    catalog_path: Path,
    configured_pmtiles_url: str = "",
) -> dict[str, Any]:
    payload = json.loads(catalog_path.read_text(encoding="utf-8"))
    spain = validate_catalog_payload(payload, configured_pmtiles_url)

    request = urllib.request.Request(
        spain["downloadUrl"],
        method="HEAD",
        headers={"User-Agent": "Espana-Outdoor-Catalog-Smoke/1.0"},
    )
    try:
        opener = urllib.request.build_opener(HTTPSOnlyRedirectHandler())
        with opener.open(request, timeout=15) as response:
            if response.status != 200:
                raise ValueError(f"PMTiles HEAD returned HTTP {response.status}.")
            final_url = urllib.parse.urlparse(response.geturl())
            if final_url.scheme != "https" or not final_url.hostname:
                raise ValueError("PMTiles HEAD redirected to a non-HTTPS URL.")
            if final_url.username or final_url.password:
                raise ValueError("PMTiles final URL must not include embedded credentials.")
            remote_size = response.headers.get("Content-Length")
    except (OSError, urllib.error.URLError) as exc:
        raise ValueError(f"PMTiles HEAD request failed: {exc}") from exc

    if remote_size is None:
        raise ValueError("PMTiles HEAD must provide Content-Length.")
    if remote_size is not None:
        try:
            parsed_remote_size = int(remote_size)
        except ValueError as exc:
            raise ValueError("PMTiles HEAD returned a non-integer Content-Length.") from exc
        if parsed_remote_size != spain["sizeBytes"]:
            raise ValueError(
                "Catalog sizeBytes does not match PMTiles Content-Length "
                f"({spain['sizeBytes']} != {parsed_remote_size})."
            )

    print("catalog_entry=valid")
    print("catalog_spain=valid")
    print("pmtiles_head=valid")
    if configured_pmtiles_url:
        print("configured_map_url_matches_catalog=true")
    return spain


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog-file", type=Path, required=True)
    args = parser.parse_args()

    catalog_url = os.environ.get("OFFLINE_CATALOG_URL", "").strip()
    configured_pmtiles_url = os.environ.get("MAP_PMTILES_URL", "").strip()
    if not catalog_url.startswith("https://"):
        print("Catalog validation error: OFFLINE_CATALOG_URL must use HTTPS.", file=sys.stderr)
        return 1

    try:
        validate_catalog_file(
            args.catalog_file,
            configured_pmtiles_url,
        )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"Catalog validation error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
